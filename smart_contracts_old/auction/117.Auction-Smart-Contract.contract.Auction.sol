pragma solidity ^0.4.17;

contract Auction{
    
    mapping( address => uint) bidder;
    mapping(address => bool) bidderCheck;
    address public owner;
    uint public totalBidder;
    
    bool ended;
    
    address public beneficiary;
    address public highestBidder;
    uint public highestBid;
    
    
    modifier restricted(){
        require(msg.sender == owner);
        _;
    }
    
    
    function Auction() public{
        owner = msg.sender;
        beneficiary = msg.sender;
        
    }
    
    
    function enrollBidder() payable public{
        
        require(!ended);
        
        address user = msg.sender;
        
        require(!bidderCheck[user]);
        bidderCheck[user] = true;
        totalBidder++;
        
    }
    
    function bid() payable public{
        
        require(!ended);
        
        address user = msg.sender;
        require(bidderCheck[user]);
        
        require(msg.value > highestBid);
        
        highestBid = msg.value;
        highestBidder= user;
        
        bidder[user] += msg.value;
        
       
    }
    
    
    function bidderBalance() public view returns(uint){
        require(!ended);
        return bidder[msg.sender];
    }
    
    function endBid() restricted public{
        
        require(!ended);
        
        beneficiary.transfer(highestBid);
        
        bidder[highestBidder] -= highestBid;
        
        ended= true;
        
    }
    
}   