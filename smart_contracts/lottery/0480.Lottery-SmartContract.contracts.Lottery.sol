// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager;
    uint256 public noOfParticipants;
    address payable[] public participants;

    constructor() {
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager is allowed");
        _;
    }

    function participate() public payable {
        require(msg.sender != manager, "Manager can not participate");
        require(msg.value == 2 ether, "Participation fee is 2 ether");
        noOfParticipants++;
        participants.push(payable(msg.sender));
    }

    function selectWinner() public onlyManager {
        require(noOfParticipants >= 3, "At least 3 participants require");
        uint256 randomNumber = block.timestamp % noOfParticipants; //should not use this to generate random number instead use oracles like chainlink;
        payable(participants[randomNumber]).transfer(address(this).balance);
        participants = new address payable[](0);
    }
}
