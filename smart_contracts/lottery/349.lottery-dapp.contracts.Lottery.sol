
// spdx-license-identifier:mit;
pragma solidity ^0.8.8;

contract Lottery{
    address public manager;
    address payable[] public participants;
    address payable public winner;

    constructor() public {
        manager = payable(msg.sender);
    }

    mapping(address => uint) public totalParticipant;

    function getManager() public view returns(address){
        return manager;
    }

    function enter() external payable{
        require(manager != msg.sender, "manager cant participate");
        require(msg.value==1 ether,"entry value is 1 ether");
        require(totalParticipant[msg.sender] == 0, "you have already participated");
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        require(msg.sender==manager,"only manager can call this function");
        return address(this).balance;
    }

    function randomAddress()private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp, participants.length)));
    }
    function selectWinner() public {
       require(msg.sender==manager,"you are not the manager");
       require(participants.length >= 3, "there should be atleast 3 players");
       uint r =randomAddress();
       uint index = r % participants.length;
       winner = participants[index];
       winner.transfer(getBalance());

    }

    function getAllParticipants() public view returns(address payable[] memory){
        return participants;
    }
}

