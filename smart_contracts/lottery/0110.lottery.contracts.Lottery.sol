// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
pragma experimental ABIEncoderV2;
// import "@openzeppelin/contracts/access/Ownable.sol";

// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

enum State {
    Open,
    Closed,
    InProgress
}

contract Lottery {
    using SafeMath for uint256;
    // State variables
    address public deployer;
    address payable public creator;
    uint256 public priceTicket;
    uint256 public created;
    uint256 public currentBalance;
    uint256 public deadline;
    uint256 public id;
    State public state = State.Open; // initialize on create
    mapping(address => uint256) public contributors;
    address[] public players;
    uint256 playersLength;
    uint256 public numberOfWinners;
    uint256[] public rewards;
    uint256 limitTickets;
    address[] public tickets;
    uint256 lotteryPot = 0;

    function getDeployerAddress() public view returns (address) {
        return deployer;
    }

    struct winner {
        uint256 id;
        uint256 amount;
        address account;
    }
    mapping(uint256 => winner) winners;
    uint256[] public winnerIds;

    event LotteryStateChanged(State newState);
    event Transfer(address indexed _from, uint256 _value);
    event LogWinnerSelectionStarted(string message);
    event LogWinnerSelected(address winner);

    constructor(
        address payable projectDeployer,
        address payable projectStarter,
        uint256 projectId,
        uint256 deadlineTime,
        uint256 projectTicketPrice,
        uint256[] memory lotteryRewards,
        uint256 lotteryLimitTickets
    ) {
        // this is for testing
        // uint256 totalPercent = 0;
        // for (uint256 i = 0; i < rewards.length; i++) {
        //     totalPercent += uint256(rewards[i]);
        // }
        // require(totalPercent == 100, "The sum of prizes is not 100 (percent)");
        deployer = projectDeployer;
        creator = projectStarter;
        id = projectId;
        priceTicket = projectTicketPrice;
        deadline = deadlineTime;
        currentBalance = 0;
        created = block.timestamp;
        numberOfWinners = lotteryRewards.length;
        rewards = lotteryRewards;
        limitTickets = lotteryLimitTickets;
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }

    function getTicketPrice() public view returns (uint256) {
        return priceTicket;
    }

    function getDeadline() public view returns (uint256) {
        return deadline;
    }

    function getLimitTicket() public view returns (uint256) {
        return limitTickets;
    }

    function getRewards() public view returns (uint256[] memory) {
        return rewards;
    }

    function getContributed(address _address) public view returns (uint256) {
        return contributors[_address];
    }

    function getState() public view returns (State) {
        return state;
    }

    function getTicketsCount() public view returns (uint256) {
        return tickets.length;
    }

    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function getWinner(uint256 index) public view returns (address) {
        return winners[index].account;
    }

    function getWinnerAmount(uint256 index) public view returns (uint256) {
        return winners[index].amount;
    }

    function getNumberOfWinners() public view returns (uint256) {
        return rewards.length;
    }

    function getOwner() public view returns (address) {
        return creator;
    }

    function getBalance() public view returns (uint256) {
        return currentBalance;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function getEntrantCount() public view returns (uint256) {
        return players.length;
    }

    function winnerHasNotBeenSet() private view returns (bool) {
        return winnerIds.length == 0;
    }

    function pickWinnerIsInProgress() private view returns (bool) {
        return state == State.InProgress;
    }

    function kill() external {
        require(msg.sender == creator, "Only the owner can kill this contract");
        selfdestruct(creator);
    }

    function buyTicket(uint256 ticketAmount) public payable returns (uint256) {
        require(block.timestamp < deadline, "The lottery has ended");
        require(msg.value >= priceTicket, "Invalid entry fee provided");
        require(
            winnerHasNotBeenSet(),
            "Lottery has already been closed. Winners were already selected."
        );

        uint256 ticketsByAcc = this.getEnteredTicketsByAccount(msg.sender) +
            ticketAmount;
        require(
            limitTickets >= ticketsByAcc,
            "Entered tickets should not be over the limit ticket by address."
        );

        contributors[msg.sender] = contributors[msg.sender].add(msg.value);
        currentBalance = currentBalance.add(msg.value);

        for (uint256 i = 0; i < ticketAmount; i++) {
            tickets.push(msg.sender);
        }

        bool doesPlayerEntered = false;
        for (uint256 i = 0; i < players.length; i++) {
            if (msg.sender == players[i]) {
                doesPlayerEntered = true;
            }
        }

        if (!doesPlayerEntered) {
            players.push(msg.sender);
        }

        emit Transfer(msg.sender, msg.value);
        lotteryPot = (address(this).balance * 95) / 100;
        return tickets.length;
    }

    function getRewardsByAccount(address _address)
        public
        view
        returns (uint256)
    {
        uint256 rewardsWon = 0;
        for (uint256 i = 0; i < numberOfWinners; i++) {
            winner storage ltWinner = winners[i];
            if (ltWinner.account == _address) {
                rewardsWon = uint256(rewardsWon) + uint256(ltWinner.amount);
            }
        }
        return rewardsWon;
    }

    function getEnteredTicketsByAccount(address _address)
        public
        view
        returns (uint256)
    {
        uint256 ticketsByAccount = 0;
        for (uint256 i = 0; i < tickets.length; i++) {
            if (_address == tickets[i]) {
                ticketsByAccount++;
            }
        }
        return ticketsByAccount;
    }

    function getWinProbabiltyByAccount(address _address)
        public
        view
        returns (uint256)
    {
        // vraciam percenta + navyse 2 desatinimi cislami,
        // kvoli tomu ze v Solidity sa neda pracovat s float
        // na frontende ak vstup predelim 100, dostanem percenta
        // napr 21,58
        return
            (this.getEnteredTicketsByAccount(_address) * 10000) /
            tickets.length;
    }

    function shuffle() private {
        for (uint256 i = 0; i < tickets.length; i++) {
            uint256 n = i +
                (uint256(keccak256(abi.encodePacked(block.timestamp))) %
                    (tickets.length - i));
            address temp = tickets[n];
            tickets[n] = tickets[i];
            tickets[i] = temp;
        }
    }

    function random(address[] memory roundTickets)
        private
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        roundTickets
                    )
                )
            );
    }

    function pickWinner() public payable isCreator {
        require(block.timestamp > deadline, "Lottery is open");
        require(winnerHasNotBeenSet(), "Winner has already been selected");
        require(
            !pickWinnerIsInProgress(),
            "Winners selection already in progress"
        );
        _changeState(State.InProgress);
        uint256 reward;
        currentBalance = address(this).balance;
        uint256 winnersReward = 95;
        lotteryPot = (address(this).balance * winnersReward) / 100;

        if (players.length <= numberOfWinners) {
            for (uint256 i = 0; i < players.length; i++) {
                address player = players[i];
                payable(player).transfer(contributors[player]);
            }
        } else {
            for (uint256 i = 0; i < numberOfWinners; i++) {
                // calculate the REWARD based on draw ROUND
                if (tickets.length == 0) {
                    break;
                }

                emit LogWinnerSelectionStarted(
                    string(
                        abi.encodePacked(
                            "Winner ",
                            (i + 1),
                            " selection has started!"
                        )
                    )
                );
                reward =
                    ((uint256(rewards[i]) * currentBalance) / uint256(10000)) *
                    uint256(winnersReward);

                // shuffle tickets in round i
                shuffle();

                // get random address from tickets
                uint256 index = random(tickets) % tickets.length;

                // set the winner properties
                winner storage ltWinner = winners[i];
                ltWinner.account = tickets[index];
                ltWinner.amount = reward;
                winnerIds.push(i);

                // move out winner tickets
                for (uint256 j = 0; j <= tickets.length - 1; j++) {
                    if (tickets[j] == ltWinner.account) {
                        address toMove = tickets[tickets.length - 1];
                        while (
                            toMove == ltWinner.account &&
                            tickets.length - 1 != j
                        ) {
                            tickets.pop();
                            toMove = tickets[tickets.length - 1];
                        }
                        deleteUser(j);
                    }
                }

                // send reward to the winner
                payable(ltWinner.account).transfer(reward);
            }
        }

        // reward for creator 3%
        currentBalance = address(this).balance;
        reward = (currentBalance * 60) / 100;
        payable(creator).transfer(reward);

        // reward for deployer 2%
        payable(getDeployerAddress()).transfer(address(this).balance);
        currentBalance = address(this).balance;
        _changeState(State.Closed);
    }

    // Modifier to check if the function caller is the project creator
    modifier isCreator() {
        require(
            msg.sender == creator,
            "Only the contract creator can execute this action"
        );
        _;
    }

    event LogDeleteUser(address indexed userAddress, uint256 index);

    function deleteUser(uint256 userIndex) public returns (address index) {
        address toDelete = tickets[userIndex];
        uint256 lastIndex = tickets.length - 1;
        swap(userIndex, lastIndex);
        tickets.pop();

        return toDelete;
    }

    function swap(uint256 userIndex, uint256 lastIndex) private {
        address toDelete = tickets[userIndex];
        tickets[userIndex] = tickets[lastIndex];
        tickets[lastIndex] = toDelete;
    }

    function revealWinners()
        public
        view
        returns (uint256[] memory, address[] memory)
    {
        require(
            block.timestamp > deadline,
            "The winners have not been announced yet."
        );

        address[] memory addrs = new address[](winnerIds.length);
        uint256[] memory amounts = new uint256[](winnerIds.length);

        for (uint256 i = 0; i < winnerIds.length; i++) {
            winner storage ltWinner = winners[i];
            addrs[i] = ltWinner.account;
            amounts[i] = ltWinner.amount;
        }
        return (amounts, addrs);
    }

    /** @dev Function to get specific information about the project.
     * @return projectStarter Returns all the project's details
     */
    function getDetails(address account)
        public
        view
        returns (
            address payable projectStarter,
            uint256 projectId,
            uint256 deadlineTime,
            State currentState,
            uint256 currentAmount,
            uint256 ticketPrice,
            uint256 projectPot,
            uint256 lotteryPlayersLength,
            uint256 lotteryDateCreated,
            uint256[] memory lotteryRewards,
            uint256 purchased
        )
    {
        projectStarter = creator;
        projectId = id;
        deadlineTime = deadline;
        currentState = state;
        currentAmount = currentBalance;
        ticketPrice = priceTicket;
        lotteryPlayersLength = playersLength;
        lotteryDateCreated = created;
        projectPot = lotteryPot;
        lotteryRewards = rewards;
        purchased = contributors[account];
    }

    function _changeState(State _newState) private {
        state = _newState;
        emit LotteryStateChanged(state);
    }

    function getPlayersDetails()
        public
        view
        returns (
            address[] memory lotteryPlayers,
            address[] memory lotteryTickets
        )
    {
        lotteryPlayers = players;
        lotteryTickets = tickets;
    }
}
