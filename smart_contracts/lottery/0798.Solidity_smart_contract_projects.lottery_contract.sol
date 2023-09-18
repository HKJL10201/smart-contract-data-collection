// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract lottery{
    address public manager;
    address payable[] public participants;

    constructor(){
        manager=msg.sender;
    }

  function getether ()public payable{
        require(msg.value== 1 ether,"not sufficient fees");
        participants.push(payable(msg.sender));
    }

    function showether() public view returns(uint){
        require(msg.sender==manager,"you are not manager...");
        return address(this).balance;
    }

    function show_particpants() public view returns(uint){
        return participants.length;
    }

    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,participants.length)));
    }

    function selectwinner() public {
        require(msg.sender==manager);
        require(participants.length >= 3);

        uint r = random();
        uint winner= r%participants.length;
        participants[winner].transfer(showether());
        participants= new address payable[](0);

    }

}