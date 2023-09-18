// SPDX-License-Identifier: MIT
pragma solidity ^0.5.17;

contract Lottery {
    address private manager;
    address[] private participants;

    constructor() public {
      manager = msg.sender;
    }
    
    function enter() public payable{
      require(msg.sender != manager, "Manager cannot participant in this lottery");

      for (uint index; index < participants.length; index++){
        require(participants[index] != msg.sender, "You've previously joined the lottery");
      }

      require(msg.value > 0.01 ether, "you must send more than 0.01 ether");

      participants.push(msg.sender);
    }

    function allParticipants() public view returns (address[] memory) {
        return participants;
    }

    function lottery() public onlyManager {
        require(address(this).balance > 0 ether, "There is no pot money");

        uint totalPeople = participants.length;
        uint luckyDrawIndex = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, totalPeople))) % totalPeople;
        address winner = participants[luckyDrawIndex];

        // for ^0.5.17 solidity
        address payable payableAddress = address(uint(winner));
        payableAddress.transfer(address(this).balance);

        // for ^0.8.11 solidity 
        // payable(winner).transfer(address(this).balance);

        participants = new address[](0);
    }

    modifier onlyManager() {
      require(manager == msg.sender, "You must be the manager to execute this function");
      _;
    }

}
