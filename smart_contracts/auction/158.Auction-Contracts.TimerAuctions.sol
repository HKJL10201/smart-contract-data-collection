pragma solidity 0.5.11;

import "./BaseAuction.sol";
import "./Withdrawable.sol";

contract TimerAuction is BaseAuction, Withdrawable {
    
    string public item;
    uint public auctionEnd;
    address payable public maxBidder;
    uint public maxBid;
    bool public ended;
    
    constructor(string memory _item , uint _durationMinutes) public { //memory keyword is to be used with strings in constructor to assign memory
        item = _item;
        auctionEnd =now + (_durationMinutes * 1 minutes);
    }

    function bid() external payable {
        require(now < auctionEnd);
        require(msg.value > maxBid);
        
        if(maxBidder != address(0)) {
            // maxBidder.transfer(maxBid);    //NOT A GOOd PRactice because calling an exteranl function and after it we are updating our function values
            pendingWithdrawls[maxBidder] += maxBid;
            
        }
    
        maxBidder =msg.sender;
        maxBid = msg.value;
        emit BidAccepted(maxBidder, maxBid);
        
        
    }
    
    function end() public {
        require(!ended);
        require(now>=auctionEnd);
        ended=true;
        
        emit AuctionComplete(maxBidder,maxBid);
        
        owner.transfer(maxBid);
    }
    
}
