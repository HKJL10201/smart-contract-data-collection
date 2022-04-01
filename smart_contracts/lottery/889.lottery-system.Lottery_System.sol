pragma solidity >=0.5.13 < 0.7.3;

contract LotterySystem{
    
    address owner;
    mapping(address => uint)public addressOfLotteryParticipants; 
    
    address[] addressofParticipant; 
    
    constructor() public{
        owner = msg.sender;
    }
    
    function receiveEtherforParticipation() payable public{
        require(msg.value>= 1 ether,"You need atleast 1 Ether to participate!!");
        require(contains(msg.sender)==0,"You are already part of lottery!!");
        addressOfLotteryParticipants[msg.sender] = msg.value;
        addressofParticipant.push(msg.sender);
    }
    
    function randomNumberFunction() private view returns(uint){
        uint randomNumber = uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,
        msg.sender,"User",addressofParticipant))) % addressofParticipant.length;
        return (randomNumber); 
    }
    
    function transferEtherForWinner() public onlyOwner{
        uint randomWinner = randomNumberFunction();
        address payable winner = payable (addressofParticipant[randomWinner]);
        winner.transfer(address(this).balance);
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "Owner only has access to this!!");
        _;
    }
    
    function contains(address _addr) private view returns(uint){
        return addressOfLotteryParticipants[_addr];
    }
    
}