pragma solidity ^0.8.19;

contract Lottery{
    address public manager;
    address payable[] public participants;
    
    constructor(){
        manager=msg.sender;
    }

    receive() external payable // can be used only once and a specialized function with no parameters 
    {
        require(msg.value==1 ether);
        participants.push(payable(msg.sender));
    } 
    function getBalance() public view returns(uint)
    {
        require(msg.sender==manager);
        return address(this).balance;
    }

    function random() public view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }
    function selectWinner() public{
        require(msg.sender==manager);
        require(participants.length>=3);
        uint rand=random();
        address payable winner;
        uint index=rand%participants.length;
        winner=participants[index];
        winner.transfer(getBalance());
        participants=new address payable[](0);
    }
}