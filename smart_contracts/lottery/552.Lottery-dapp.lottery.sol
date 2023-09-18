// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Lottery{
    address public manager;
    address payable[] public participants;

    constructor(){
        manager=msg.sender;
    }
    receive() external payable{
        require(msg.value==2 ether);
        participants.push(payable(msg.sender));
    }
    function getbalance() public view returns(uint contractbalance){
        require(msg.sender==manager);
        return address(this).balance;
    }
    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }
    function selectwinner() public view returns(address winneris){
        require(msg.sender==manager);
        require(participants.length>=3);
        address payable winner;
        uint r=random();
        uint s=r % participants.length;
        winner=participants[s];
        return winner;
    }
}