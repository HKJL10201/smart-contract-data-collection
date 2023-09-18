pragma solidity ^0.4.0;

/* 
Authors: Abhimanyu Gupta (aag245), Claudia Dabrowski (cd432)

This contract allows for a person to sell information to the blockchain. 
It supports starting an auction for the information, bidding on the info,
withdrawing funds if your bid does not win, and accessing the information if you
do win (via the highest bid).
*/
contract Auction {
    
    //Static Auction related fields
    address public bidMaster;
    uint private endTime;
    uint public minimumBid; //In Wei!
    bool private auctionEnded;
    bool private hasReleased;
    string private valuableInformation;
    
    //Bid Counters
    address public highestBidder;
    uint public highestBid;
    
    //Bids that may need to be returned
    mapping(address => uint) returnBids;
    
    //Events
    event HighestBidChanged(address bidder, uint bid);
    event AuctionComplete(address winner, uint bid);
    
    //Kick start the Auction
    function startAuction(address _bidMaster, uint _duration, uint _minBid, string _info) public {
        bidMaster = _bidMaster;
        hasReleased = false;
        auctionEnded = false;
    
        //Auction must last at least 1 minute
        require(_duration > 60);
        require(_minBid >= 0);
        require(_minToRelease >= 0);
            
        endTime = now + _duration;
        minimumBid = _minBid;
        highestBid = 0;
        valuableInformation = _info;
    }
    
    //Bid for the item in the auction
    function bid() public payable {
        //Valid auction time
        require(now <= endTime);
        
        //Meets minimum criteria
        require(msg.value > minimumBid);
        
        //Is higher than current bid
        require(msg.value > highestBid);
        
        //queue previous bid for return
        if (highestBid != 0){
            returnBids[highestBidder] += highestBid;
        }
        
        //update bid counters
        highestBidder = msg.sender;
        highestBid = msg.value;
        HighestBidChanged(highestBidder, highestBid);
    }
    
    //Withdraw funds from a failed bid
    function withdraw() public returns (bool){
        uint returnAmt = returnBids[msg.sender];
        if (returnAmt > 0) {
            //Prevents bidders from calling more times
            returnBids[msg.sender] = 0;
            if (!msg.sender.send(returnAmt)){
                returnBids[msg.sender] += returnAmt;
                return false;
            }
        }
        return true;
    }
    
    //End the auction and clean update
    function endAuction() public {
        require(now >= endTime);
        require(!auctionEnded);
        
        auctionEnded = true;
        AuctionComplete(highestBidder, highestBid);
        
        bidMaster.transfer(highestBid);
    }
    
    //Allow winner to see valuableInformation
    function seeInfo() internal view returns (string){
        if (auctionEnded) {
            if (msg.sender == highestBidder) {
                return valuableInformation;
            }
        }
    }
}