// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.9.0;

contract lottery{
    address public manager;
    address payable[] public participants;

    constructor()
    {
        manager=msg.sender;
    }

    receive() external payable
    {
        require(msg.value== 1 ether);
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint)
    {
        require(msg.sender==manager);
        return address(this).balance;
    }
    function Random() private view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }
    function Winner() public 
    {
        require(msg.sender==manager);
        require(participants.length >= 3);
        uint r = Random();
        address payable winner;
        uint index = r%participants.length;
        winner=participants[index];
        winner.transfer(getBalance());
        participants = new address payable[](0); 
    }
}