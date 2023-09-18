pragma solidity >=0.7.0  < 0.8.0;

contract Auction{
    address payable public beneficiary;
    uint public auctionEndTime;
    string public antiqueName;
    uint public basePrice;
    uint public datedYear;
    
    address public highestBidder;
    uint public highestBid;
    
    mapping (address => uint) public pendingReturns;
    
    bool ended = false;
    
    event HighestBidIncrease(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    
    constructor (uint _biddingTime, address payable _beneficiary)
    {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
    }
    
    function bid () public payable
    {
        if(block.timestamp > auctionEndTime){
            revert("The bidding has already ended! :( ");
        }
        
        if(msg.value <= highestBid){
            revert("There is already a higher or equal bid -_- " );
        }
        
        if(highestBid !=0){
            pendingReturns[highestBidder] += highestBid;
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncrease(msg.sender, msg.value);
        
    }
    
    function withdraw() public returns (bool){
        uint amount = pendingReturns[msg.sender];
        if (amount > 0){
            pendingReturns[msg.sender] = 0;
            
            if(!payable (msg.sender).send (amount)){
                pendingReturns[msg.sender] = amount;
                return false;
            }
            }
            return true;
        }
        
    
    
    function auctionEnd() public {
        
        if(block.timestamp < auctionEndTime){
            revert("The bidding has not ended yet :P ");
        }
        
        if(ended){
            revert("The function auctionEnded has already been called >_< ");
        }
        
        ended = true;
        emit auctionEnded(highestBidder, highestBid);
        
        beneficiary.transfer(highestBid);
        
    }
    
    
}