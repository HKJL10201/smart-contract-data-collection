// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
pragma experimental ABIEncoderV2;
import "./Lottery.sol";

contract LotteryBuilder {
    using SafeMath for uint256;

    // List of existing projects
    Lottery[] private lotteries;
    address payable public owner;

    constructor() {
        owner = msg.sender;
    }

    // Event that will be emitted whenever a new project is started
    event ProjectStarted(
        address contractAddress,
        address deployer,
        address creator,
        uint256 id,
        uint256 deadline,
        uint256 ticketPrice,
        uint256[] rewards,
        uint256 limitTickets
    );

    /** @dev Function to start a new project.
     * @param deadlineDate Project deadline in days
     * @param ticketPrice Project goal in wei
     */
    function startProject(
        address payable creator,
        uint256 deadlineDate,
        uint256 ticketPrice,
        uint256[] calldata rewards,
        uint256 limitTickets
    ) external {
        uint256 totalPercent = 0;
        for (uint256 i = 0; i < rewards.length; i++) {
            totalPercent += rewards[i];
        }
        require(totalPercent == 100, "The sum of prizes is not 100 (percent)");
        uint256 raiseUntil = deadlineDate;
        uint256 id = lotteries.length;
        Lottery newProject = new Lottery(
            owner,
            creator,
            id,
            raiseUntil,
            ticketPrice,
            rewards,
            limitTickets
        );
        lotteries.push(newProject);
        emit ProjectStarted(
            address(newProject),
            owner,
            creator,
            lotteries.length,
            raiseUntil,
            ticketPrice,
            rewards,
            limitTickets
        );
    }

    struct Winners {
        uint256[] values;
        address[] accounts;
    }
    mapping(uint256 => Winners) allWinners;

    struct participated {
        address lotteryAddress;
        uint256 value;
        uint256 ticketsAmount;
        State state;
        bool won;
        uint256 amountWon;
    }
    mapping(uint256 => participated) participatedList;

    function getOwner() public view returns (address) {
        return owner;
    }

    function participatedByAddress(address _address)
        public
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            State[] memory,
            bool[] memory,
            uint256[] memory
        )
    {
        uint256 participatedIndex = 0;
        for (uint256 i = 0; i < lotteries.length; i++) {
            Lottery ltr = lotteries[i];
            address[] memory players = ltr.getPlayers();
            for (uint256 j = 0; j < players.length; j++) {
                if (players[j] == _address) {
                    participated storage par = participatedList[
                        participatedIndex
                    ];
                    par.lotteryAddress = ltr.getContractAddress();
                    par.value = ltr.getContributed(_address);
                    par.ticketsAmount = ltr.getEnteredTicketsByAccount(
                        _address
                    );
                    par.state = ltr.getState();
                    par.won = false;
                    par.amountWon = 0;

                    for (uint256 k = 0; k < ltr.getNumberOfWinners(); k++) {
                        if (_address == ltr.getWinner(k)) {
                            par.won = true;
                            par.amountWon = ltr.getWinnerAmount(k);
                        }
                    }
                    participatedIndex++;
                }
            }
        }

        address[] memory addrs = new address[](participatedIndex);
        uint256[] memory funds = new uint256[](participatedIndex);
        uint256[] memory tickets = new uint256[](participatedIndex);
        State[] memory states = new State[](participatedIndex);
        bool[] memory won = new bool[](participatedIndex);
        uint256[] memory amountWon = new uint256[](participatedIndex);

        for (uint256 i = 0; i < participatedIndex; i++) {
            participated storage pa = participatedList[i];
            addrs[i] = pa.lotteryAddress;
            funds[i] = pa.value;
            tickets[i] = pa.ticketsAmount;
            states[i] = pa.state;
            won[i] = pa.won;
            amountWon[i] = pa.amountWon;
        }

        return (addrs, funds, tickets, states, won, amountWon);
    }

    // function getTotalSpent(address _address) external view returns (uint256) {
    //     uint256 totalSpent = 0;
    //     totalSpent = this.getRewardsWonByAddress(_address) - this.getSpentState(_address);
    //     return totalSpent;
    // }

    function getSpentState(address _address) external view returns (uint256) {
        uint256 spent = 0;

        for (uint256 i = 0; i < lotteries.length; i++) {
            Lottery ltr = lotteries[i];
            spent = spent + uint256(ltr.getContributed(_address));
        }

        return spent;
    }

    function getRewardsWonByAddress(address _address)
        external
        view
        returns (uint256)
    {
        uint256 rewardsWon = 0;

        for (uint256 i = 0; i < lotteries.length; i++) {
            Lottery ltr = lotteries[i];
            rewardsWon =
                uint256(rewardsWon) +
                uint256(ltr.getRewardsByAccount(_address));
        }
        return rewardsWon;
    }

    event RevealLatestWinners(Winners[] _a);

    function getLatestWinners() external view returns (Winners[] memory) {
        Lottery[] memory closedLotteries = this.returnClosedProjects();

        Winners[] memory winners = new Winners[](closedLotteries.length);
        if (closedLotteries.length != 0) {
            for (uint256 i = 0; i < closedLotteries.length; i++) {
                Lottery ltr = closedLotteries[i];
                (uint256[] memory values, address[] memory accounts) = ltr
                    .revealWinners();
                winners[i].values = values;
                winners[i].accounts = accounts;
            }
        }
        return winners;
    }

    function returnClosedProjects() external view returns (Lottery[] memory) {
        return this.getProjectsByState(State.Closed);
    }

    function returnOpenProjects() external view returns (Lottery[] memory) {
        return this.getProjectsByState(State.Open);
    }

    function getProjectsByState(State state)
        external
        view
        returns (Lottery[] memory)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < lotteries.length; i++) {
            Lottery ltr = lotteries[i];
            if (ltr.getState() == state) {
                count++;
            }
        }
        Lottery[] memory ltrs = new Lottery[](count);
        count = 0;
        for (uint256 i = 0; i < lotteries.length; i++) {
            Lottery ltr = lotteries[i];
            if (ltr.getState() == state) {
                ltrs[count] = ltr;
                count++;
            }
        }
        return ltrs;
    }

    /** @dev Function to get all projects' contract addresses.
     * @return A list of all projects' contract addreses
     */
    function returnAllLotteries() external view returns (Lottery[] memory) {
        return lotteries;
    }
}
