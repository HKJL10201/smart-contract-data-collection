pragma solidity ^0.8.11;

contract Auction {

    address payable public owner;
    uint public minimumBid;
    uint public startTime;
    uint public bidEnd;
    uint public endAuction;
    uint public currentTime;
    uint public highestBid = 0;
    uint public bid;


    address payable public bidder;
    address public winner;


    event LogBid(address bidder, uint bid, uint highestBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);

    constructor() {

    owner = payable(0x1aa191e9323a27C61fD1922b581829f534F9c5F1);
    startTime= 5 ;
    bidEnd =  5 ;
    endAuction = 5 ;
    minimumBid = 10* 1000000000000000000;
    }

   
    function getHighestBid()
    public
    returns (uint)
    {
        return highestBid;
    }
    
    function advanceTime()
    public
    {
        currentTime = currentTime+1;
    }


    function placeBid()
        public
        payable

        returns (bool success)
    {
        
        if (msg.value>highestBid){
            bidder.transfer(highestBid);
        }

        bidder = payable(msg.sender);
        bid = msg.value;

        if (bid < minimumBid || bid <= highestBid) {
            bidder.transfer(bid);
            return false;
        }

        if (bid > minimumBid && bid > highestBid){
            if (bid > highestBid) {
                if (bidder != winner) {
                            winner = bidder;
                        }
                highestBid = bid;
                emit LogBid(msg.sender, bid,  highestBid);
            
                return true;
            } 
        }

    }

    function withdraw()
    public
    returns (bool success)
    {
        owner.transfer(highestBid);

        emit LogWithdrawal(owner, owner, highestBid);

        return true;
    }


    receive() external payable  { 
        placeBid();
    }

    fallback() external payable {
        placeBid();
    }


}
