// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Lottery {
    uint drawing;
    uint ticketPrice;
    address payable[] entrants;
    address public admin;

    mapping(address => bool) hasTicket;

    constructor() {
        admin = msg.sender;
        ticketPrice = 1 ether;
        drawing = block.timestamp + 1 days;
    }
    function enterLottery() external payable {
        require(msg.value == ticketPrice, "have to pay the exact amount for the ticket");

        // ensure entrants haven't already bought tickets
        require(hasTicket[msg.sender] == false, "can only buy one ticket");

        // ensure sender has enough money in their account
        require(msg.sender.balance > ticketPrice, "balance too low");

        // buy ticket
        payable(msg.sender).transfer(msg.value);

        // ensure player now has a ticket
        hasTicket[msg.sender] = true;

        // update list of entries
        entrants.push(payable(msg.sender));
    }

    function randomNumber() private view returns(uint) {
        // generate a random number for how the winner will be decided
        return uint(keccak256(abi.encode(block.difficulty, block.timestamp, entrants, block.number)));
    }

    function decideWinner() internal onlyAdmin {
        // ensure the time of the drawing is at or after the drawing close date of 1 week
        require(block.timestamp >= drawing, "lottery is still ongoing");
        
        // decide winner 
        uint won = randomNumber() % entrants.length;

        // transfer the prize to their address
        entrants[won].transfer(address(this).balance);

        // reset lottery
        entrants = new address payable[](0);
    }

    // modifier to ensure only the owner of the smart-contract can decide the winner
    // and transfer the prize to the winners address
    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can call this function");
        _;
    }
}