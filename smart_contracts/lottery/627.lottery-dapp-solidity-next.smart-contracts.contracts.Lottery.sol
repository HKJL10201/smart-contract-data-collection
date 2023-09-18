// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Lottery {
    uint256 private constant TICKET_PRICE = 0.025 ether;
    uint256 private constant SERVICE_FEE = 0.005 ether;
    uint256 private constant MAX_TICKETS = 100;
    uint256 private duration = 5 minutes;
    uint256 private commissionEarned;
    address[] private tickets;
    mapping(address => uint256) winnersToAmount;
    uint256 private expiration;
    address recentWinner;
    uint256 recentWinnerAmount;
    address private immutable lotteryOperator;

    modifier isLotteryOperator() {
        require(
            lotteryOperator == msg.sender,
            "You are not a lottery operator"
        );
        _;
    }
    modifier isDrawActive() {
        require(block.timestamp < expiration, "Lottery expired");
        _;
    }

    constructor() {
        lotteryOperator = msg.sender;
        commissionEarned = 0;
    }

    function startDraw() public isLotteryOperator {
        require(tickets.length == 0, "Draw is active");
        expiration = block.timestamp + duration;
    }

    function enterDraw() public payable isDrawActive {
        require(msg.value % TICKET_PRICE == 0, "Invalid number of tickets");
        require(msg.value >= TICKET_PRICE, "Not enough ticket price");
        unchecked {
            uint256 numerOfTickets = msg.value / TICKET_PRICE;
            require(
                remainingTickets() - numerOfTickets > 0,
                "Number of tickets exceeds maximum ticket"
            );
            for (uint i = 0; i < numerOfTickets; i++) {
                tickets.push(msg.sender);
            }
        }
    }

    function drawWinner() public isLotteryOperator {
        require(tickets.length > 0, "No tickets purchased");
        // require(block.timestamp > expiration, "Draw is still active");
        bytes32 blockHash = blockhash(block.number);
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, blockHash))
        );
        unchecked {
            uint256 winningTicket = randomNumber % tickets.length;
            console.log(winningTicket);
            address winner = tickets[winningTicket];
            console.log(winner);
            uint256 winningAmount = tickets.length *
                (TICKET_PRICE - SERVICE_FEE);
            console.log(winningAmount);

            winnersToAmount[winner] += winningAmount;
            commissionEarned += (tickets.length * SERVICE_FEE);
            console.log(winnersToAmount[winner], commissionEarned);

            delete tickets;
            recentWinner = winner;
            recentWinnerAmount = winningAmount;
        }
    }

    function withdrawWinnigs() public {
        require(winnersToAmount[msg.sender] > 0, "You are not a winner");
        (bool status, ) = (payable(msg.sender)).call{value: recentWinnerAmount}(
            ""
        );
        require(status, "Transfer Failed");
        winnersToAmount[msg.sender] = 0;
    }

    function withdrawCommission() public isLotteryOperator {
        require(commissionEarned > 0, "No commission available");
        (bool status, ) = lotteryOperator.call{value: commissionEarned}("");
        require(status, "Transfer Failed");
        commissionEarned = 0;
    }

    function refundAll() public {
        require(block.timestamp > expiration, "Lottery not expired yet");
        for (uint256 i = 0; i < tickets.length; i++) {
            address payable to = payable(tickets[i]);
            tickets[i] = address(0);
            (bool status, ) = to.call{value: TICKET_PRICE}("");
            require(status, "Transfer failed");
        }
        delete tickets;
    }

    function setDuration(uint256 _duration) public {
        duration = _duration;
    }

    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function getExpiration() public view returns (uint256) {
        return expiration;
    }

    function getLotteryOperator() public view returns (address) {
        return lotteryOperator;
    }

    function getTicketPrice() public pure returns (uint256) {
        return TICKET_PRICE;
    }

    function remainingTickets() public view returns (uint256) {
        return MAX_TICKETS - tickets.length;
    }

    function getCommissionsEarned()
        public
        view
        isLotteryOperator
        returns (uint256)
    {
        return commissionEarned;
    }

    function getWinnerAmount(address addr) public view returns (uint256) {
        return winnersToAmount[addr];
    }

    function checkLotterOperator() public view returns (bool) {
        return msg.sender == lotteryOperator;
    }

    function getRecentWinner() public view returns (address, uint256) {
        return (recentWinner, recentWinnerAmount);
    }
}
