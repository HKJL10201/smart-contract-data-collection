pragma solidity ^0.4.24;

import './baseauction.sol';
import './Withdrawable.sol';

contract TimerAuction is BaseAuction, Withdrawable {
    string public item;
    uint public auctionEnd;
    address public maxBidder;
    uint  public maxBid;
    bool public ended;
    
    constructor(string memory _item, uint _durationMinutes) public {
        item = _item;
        auctionEnd = now + (_durationMinutes * 1 minutes);
    }
    
    function bid() external payable{
        require(now < auctionEnd);
        require(msg.value > maxBid);
        
        if(maxBid != address(0)) {
            pendingWithdrawals[maxBidder] += maxBid;
        }
        
        maxBidder = msg.sender;
        maxBid = msg.value;
        emit BidAccepted(maxBidder, maxBid);
    }
    
    function end() public {
        require(!ended);
        require(now >= auctionEnd);
        ended = true;
        
        emit AuctionComplete(maxBidder, maxBid);
        owner.transfer(maxBid);
    }
}
