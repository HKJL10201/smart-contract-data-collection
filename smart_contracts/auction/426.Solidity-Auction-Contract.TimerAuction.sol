pragma solidity 0.4.19;

import "./BaseAuction.sol";

contract TimerAuction is BaseAuction{
    
    string public itemDesc;
    uint public auctionEnd;
    address public maxBidder;
    uint public maxBid;
    bool public ended;
    
    
    event bidAccepted(address maxBidder, uint maxBid);
    
    
    function TimerAuction(uint _durationMinutes, string _itemDesc){
        itemDesc = _itemDesc;
        auctionEnd = now + (_durationMinutes * 1 minutes);
    }
    
    function bid() payable{
        require(now < auctionEnd);
        require(msg.value > maxBid);
        
        //if all the requirements above are satisfied then we invoke this
        if(maxBidder != 0 ){
            maxBidder.send(maxBid);
        }
        
        maxBidder = msg.sender;
        maxBid = msg.value;
        bidAccepted(maxBidder,maxBid);
    }
    
    function end() ownerOnly {
        require(!ended);
        require(now >= auctionEnd);
        
        ended = true;
        
        AuctionComplete(maxBidder,maxBid);
        owner.send(maxBid);
    }
}