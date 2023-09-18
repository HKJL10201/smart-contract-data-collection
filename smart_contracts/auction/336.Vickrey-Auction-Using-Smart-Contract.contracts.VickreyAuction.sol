pragma solidity ^0.5.16;

import "./HelperAuction.sol";
import "./Auction.sol";
import "./BarbossaBrethren.sol";

///@author Rutwik , Yashwanth , Sunil and Manikanta
///@title Implementation of the Vickrey Auction

contract VickreyAuction is Auction {

    constructor () public {
        Seller = msg.sender;
        EndOfBiddingPeriod = now + 11;
        EndOfRevealingPeriod = EndOfBiddingPeriod + 4;
        IsBidRevealed[Seller] = true;
        HighestBid = 0;
        SecondHighestBid = 0;
    }
    ///@notice function to place a bid in the vickrey auction
    ///@param HashValue has the hash value of the bid placed
    function PlaceBidInVickreyAuction(bytes32 HashValue) public {
        require(msg.sender != Seller, "Seller Cannot Bid");
        Auction.PlaceBid(HashValue);
    }
    ///@notice function to reveal bid after the end of bidding time 
    ///@param BidAmount has the amount bidded
    ///@param Nonce has the nonce value stored
    ///@dev compare bid to the previous and highest and second highest and change them accordingly
    function RevealBidInVickreyAuction(uint BidAmount, uint Nonce) public {
        Auction.RevealBid(BidAmount, Nonce);
        if(BidAmount > HighestBid) {
            SecondHighestBid = HighestBid;
            HighestBid = BidAmount;
            HighestBidder = msg.sender;
        }
        else if (BidAmount > SecondHighestBid){
            SecondHighestBid = BidAmount;
        }
    }

    ///@notice function to reveal the winner of the auction
    ///@return the address of the highest bidder and the value of the second highest bid

    function BuyerOfTheItem() view public returns (address, uint) {
        // Auction.TransferEther(HighestBidder, SecondHighestBid);
        return (HighestBidder, SecondHighestBid);
    }
}