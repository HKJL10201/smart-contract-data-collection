// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

contract Lotter{

     address public Manager;
     address payable[] public participants; 
     uint256 public no_of_participants;

constructor(){
    Manager = msg.sender;
    no_of_participants=0;
    }

receive() external payable {
    require(msg.value == 1 ether,"minimum entry is one ether");
    participants.push(payable(msg.sender));
    no_of_participants++;
}

function getBalance() public view returns(uint){
    require(msg.sender==Manager,"only manager can see balance");
    return address(this).balance;
}
function Random() public view returns(uint){
    
 return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
}

function choose_winner() public returns(address){
    require(msg.sender == Manager,"only Manager can choose winner");
    require(participants.length >= 3,"you can only choose winner after more than 3 members");
    uint r = Random();
    address payable winner;
    uint index = r%participants.length;
    winner = participants[index];
    winner.transfer(getBalance());
    participants = new address payable[](0);
    return(winner);
    
}
function check_balance(address a) public payable returns(uint256){
    return (address(a).balance);
}

}