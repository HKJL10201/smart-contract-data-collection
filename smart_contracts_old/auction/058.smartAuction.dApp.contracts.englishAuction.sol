pragma solidity ^0.5.3;
import "./smartAuction.sol";

/* 
pre bidding phase: grace period, length = 30 (0 if debugging)
bidding phase: buyout then bids, length depends on the unchalleged time
post bidding phase: not used, length = 0
end phase: finalize
*/
contract englishAuction is smartAuction{
    uint buyOutPrice; //If someone pays this amount before any bid in the bidding time, the good is sold immediately without starting the auction
    uint increment; //The minimum amount you have to add to current highestBid in order to be the winning bidder
    uint unchallegedLength; //Number of blocks (excluding the current one) a bid must be unchallenged before it is considered the winning bid
    
    event buyOutEvent(address bidder, uint amount); //notify that someone buy out the good
    
    constructor(address payable seller, uint _reservePrice, uint _buyOutPrice, uint _unchallegedLength, uint _increment) 
                    smartAuction(seller, _reservePrice, 20, _unchallegedLength, 0) public {
        buyOutPrice = _buyOutPrice;
        increment = _increment; 
        unchallegedLength = _unchallegedLength;
        
        winningBid = reservePrice;
    }
    
    function buyOut() payable public {
        super.bidConditions(); //it is like a bid that always win
        
        require(buyOutPrice != 0, "NO buy out price or someone else already bidded!");
        uint amount = msg.value;
        require(amount >= buyOutPrice, "Your amount is not enough to buy out!");
        
        //pay!
        winningBid = amount;
        winningBidder = msg.sender;
        
        //The auction can be considered over, because the buyout condition is satisfied
        preBiddingLength=0;
        biddingLength=0;
        
        emit buyOutEvent(winningBidder, winningBid);
    }
    
    function bid() payable public{
        super.bidConditions();
        
        address payable bidder = msg.sender;
        uint amount = msg.value;
        require(amount > winningBid, "There is an higher bid already!");
        require(amount >= winningBid + increment, "You have to pay a minimum increment amount!");
        
        biddingLength += unchallegedLength - (biddingLength - ((block.number - creationBlock) + 1)); //increment bidding time in order to have the same unchallegedLength for each new bid
        
        //no more chances of buying out the good
        if(buyOutPrice != 0){
            buyOutPrice = 0;
        }
        
        //if exists, refund the previous winning bidder
        if(winningBidder != address(0)){
            refundTo(winningBidder, winningBid);
        }
        
        winningBid = amount;
        winningBidder = bidder;
        bidders[winningBidder] = winningBid;
        emit newHighestBidEvent(bidder, amount);
    }
    
    function finalize() public{
        super.finalizeConditions();
        //if you are here, no re-entrancy problem, because finalized has been set to true!
        
        if(winningBidder != address(0) && winningBid != 0){
            seller.transfer(winningBid);
            emit finalizeEvent(winningBidder, winningBid);
        }
        else emit noWinnerEvent();
    }

    //Getters

    function getIncrement() public view returns(uint){
        return increment;
    }

    function getBuyOutPrice() public view returns(uint){
        return buyOutPrice;
    }
}
