//SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0<0.9.0;

contract Lottery{
    address public Manager;
    address payable[] public Participants;

    constructor()
    {
        Manager = msg.sender;
    }

    receive() external payable
    {   
        require(msg.value == 1 ether);
        Participants.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint)
    {
        require(msg.sender == Manager);
        return address(this).balance;
    }

    function random() public view returns(uint)
    {
       return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,Participants.length)));
    }

    function selectWinner() public
    {
        require(msg.sender==Manager);
        require(Participants.length>=3);
        uint r=random();
        address payable winner;
        uint index = r % Participants.length;
        winner = Participants[index];
        winner.transfer(getBalance());
        Participants=new address payable[](0);
    }
}