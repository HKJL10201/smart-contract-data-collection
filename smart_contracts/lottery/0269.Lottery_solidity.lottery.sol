// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 <0.9.0;
contract lottery
{
    address public manager;
    address payable[] public participants;
    constructor()
    {
        manager=msg.sender;
    }
    receive() payable external
    {
        require(msg.value>=0.00000001 ether);
        participants.push(payable(msg.sender));
    }
    function checkBalance() public view returns(uint)
    {
        require(msg.sender==manager);
        return address(this).balance;
    }
    function randomSelect() public view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }
    function winnerSelection() public 
    {
        require(msg.sender==manager);
        require(participants.length>=3);
        uint r=randomSelect();
        uint index=r%participants.length;
        address payable winner=participants[index];
        winner.transfer(checkBalance());
        participants=new address payable[](0);
    }
}