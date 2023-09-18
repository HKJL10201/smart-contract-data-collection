pragma solidity ^0.5.16;

///@author Rutwik , Yashwanth , Sunil and Manikanta
///@title Implementation of contract that manages privacy and time remaining in the auctions
contract HelperAuction{

    address payable Seller;

    uint EndOfBiddingPeriod;
    uint EndOfRevealingPeriod;

    address internal HighestBidder;
    address internal HighestBidderBarbossa;
    uint internal HighestBid;
    uint internal HighestBidBarbossa;
    uint internal SecondHighestBid;

    ///@notice Mapping to check if the bid is revealed
    mapping(address => bool) internal IsBidRevealed;

    ///@notice Mapping To Store The Hash Value Of The Bids Placed
    mapping(address => bytes32) internal HashOfBidsPlaced;
    
    mapping(address => uint) internal BalanceOfBidders;

    ///@notice Function to calculate the time remaining for the bidding
    ///@return time remaining to bid 
    function BiddingTimeRemaining() public view returns(uint) {
        require(now < EndOfBiddingPeriod, "Bidding Time has Ended");
        return EndOfBiddingPeriod - now;
    }
    ///@notice Function to calculate the time remaining before revealing the bids
    ///@dev check the time is valid to reveal bids(it's in revealind duration)
    ///@return time remaining in revealing period
    function RevealingTimeRemaining() public view returns(uint) {
        require(now >= EndOfBiddingPeriod,"Revealing Time has not Started");
        require(now < EndOfRevealingPeriod,"Revealing Time has Ended");
        return EndOfRevealingPeriod - now;
    }
}