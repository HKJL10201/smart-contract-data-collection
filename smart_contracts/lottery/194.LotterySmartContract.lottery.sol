pragma solidity ^0.4.17;

contract Lottery{
    
    address public host;
    address[] public participants;
    uint public sumAmount;
    
    function Lottery() public{
        host = msg.sender;
    }
    
    function enterLottery() public payable{
        require(msg.value >= 0.01 ether);
        sumAmount += msg.value;
        participants.push(msg.sender);
    }
    
    function random() private view returns(uint){
        return uint(keccak256(block.difficulty , now , participants));
    }
    
    function pickWinner()public restricted{
        uint index = random()%participants.length;
        participants[index].transfer(this.balance);
    }
    
    modifier restricted{
        require(msg.sender == host);
        _;
    }
}