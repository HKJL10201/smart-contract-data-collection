//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;

contract Lottery {
    //The lottery system has a manager who governs the lottery and has power such as to initiate , re-run and end the lottery
    address payable manager;
    //A participant array is created to store the adress of the participants who sucessfully completed the payment and are a part of the lottery.
    address payable[] public participants;

    //the constructor sets the manager to the adrdress that deploys(initiates) the Lottery contract
    constructor() {
        manager = payable(msg.sender);
    }

    //We need to recieve payment from the participants only once therefore we use the recieve function and once the payment is successful the address of the payer is added to the array(list) of the participants
    receive() external payable {
        require(msg.value == 1 ether, "Not sufficient ether sent");
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint256) {
        require(msg.sender == manager, "Not authorized to view the balanace");
        return address(this).balance;
    }

    function random() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }

    function selectWinner() public {
        require(msg.sender == manager, "Not authorized to declare a winner");
        require(participants.length >= 3, "Not Enough Participants");
        uint256 x = random();
        uint256 index = x % participants.length;
        address payable winner = participants[index];
        initiateTransaction(winner);
    }

    function initiateTransaction(address payable _winner) internal {
        uint256 totalAmount = getBalance();
        uint256 div = 100;
        uint256 mul = 5;
        uint256 incentive = (mul / div) * totalAmount;
        uint256 winnerAmount = totalAmount - incentive;
        _winner.transfer(winnerAmount);
        manager.transfer(incentive);
        participants = new address payable[](0);
    }
}
