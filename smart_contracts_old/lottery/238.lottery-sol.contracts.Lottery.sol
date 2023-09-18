// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

import "./RandomNumberGenerator.sol";

contract Lottery {
    // Index of the winning player
    uint256 public winnerPlayerIndex;

    // Mapping from ticket numbers to addresses
    address[] public players;

    // Bool signifying that the lottery has ended
    bool lotteryEnded;

    // Deadline of the lottery
    uint256 public deadline;

    // Price of the lottery ticket
    uint256 public ticketPrice;

    // A seed for this contract
    uint256 seed;

    // Random Number Generator Contract
    RandomNumberGenerator rng;

    constructor(
        uint256 _seed,
        uint256 _deadline,
        address _rng
    ) payable {
        deadline = block.timestamp + (_deadline * 1 minutes);
        ticketPrice = 1 ether;
        seed = _seed;
        rng = RandomNumberGenerator(_rng);
        rng.getRandomNumber();
    }

    modifier afterDeadline() {
        require(
            block.timestamp > deadline,
            "The lottery deadline was not reached yet."
        );
        _;
    }

    modifier withinDeadline() {
        require(
            block.timestamp <= deadline,
            "This lottery has has reached it's deadline."
        );
        _;
    }

    modifier lotteryHasEnded() {
        require(block.timestamp > deadline, "This lottery is still open.");
        require(lotteryEnded, "Lottery is still ongoing");
        _;
    }

    modifier isWinner() {
        require(
            msg.sender == players[winnerPlayerIndex],
            "Sorry, you didn't win this time!"
        );
        _;
    }

    // Buys a new ticket
    function buyTicket() public payable withinDeadline {
        require(
            msg.value == ticketPrice,
            "The transaction value did not match the predefined ticket price"
        );
        players.push(msg.sender);
    }

    function claimWinningPrice() public lotteryHasEnded isWinner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function startDrawing() public afterDeadline {
        require(
            lotteryEnded == false,
            "The lottery has ended. Please check if you won the price!"
        );
        require(players.length == 0, "Not enough players participating");

        uint256 randomNumber = rng.randomResult();
        winnerPlayerIndex = (randomNumber % players.length) + 1;
        lotteryEnded = true;
    }
}
