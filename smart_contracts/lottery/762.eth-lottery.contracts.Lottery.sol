pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

contract Lottery {
    address public manager;
    address[] public participants;
    
    constructor() {
        manager = msg.sender;
    }
    
    // Function to enter the lottery
    function register() public payable {
        require(msg.value >= 0.1 ether);
        participants.push(msg.sender);
    }
        
    // Function to pick a winner from the given array of winner    
    function drawWinner() public payable restricted {
        uint idx = random() % participants.length;
        payable(participants[idx]).transfer(address(this).balance);
        
        // Reset the Lottery
        participants = new address[](0);
    }
    
    // Private function to generate a random number
    function random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants)));
    }
    
    // Modifier to restrict access to only the manager of the contract
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function getParticipants() public view returns (address[] memory) {
        return participants;
    } 
}
