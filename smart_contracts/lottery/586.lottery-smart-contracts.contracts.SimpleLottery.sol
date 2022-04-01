// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SimpleLottery {
    uint256 public constant TICKET_PRICE = 1e16; // 0.01 ether
    address[] public tickets;
    address public winner;
    uint256 public ticketingCloses;

    constructor(uint256 duration) {
        ticketingCloses = block.timestamp + duration;
    }

    function buy() public payable {
        require(msg.value >= TICKET_PRICE, "couldn't buy with that amount");
        assert(block.timestamp < ticketingCloses);
        tickets.push(msg.sender);
    }

    function drawWinner() public {
        assert(block.timestamp > ticketingCloses + 5 minutes);
        require(winner == address(0));
        // generating a random value
        bytes32 rand = keccak256(abi.encode(block.number - 1));
        winner = tickets[uint256(rand) % tickets.length];
    }

    function withdraw() public {
        require(msg.sender == winner);
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        buy();
    }
}
