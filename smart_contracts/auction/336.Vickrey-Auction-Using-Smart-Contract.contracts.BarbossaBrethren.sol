pragma solidity ^0.5.16;

import "./HelperAuction.sol";
import "./Auction.sol";
import "./VickreyAuction.sol";

///@author Rutwik , Yashwanth , Sunil and Manikanta
///@title Implementation of the Auction among the Barbossa brethren
contract BarbossaBrethren is Auction{

    VickreyAuction VA_instance;

    constructor() public {
        Seller = msg.sender;
    }
    ///@notice function to connect with the vickrey auction
    ///@param TempAddress has the address of the vickery auction

    function ConnectWithVickeryAuction(address TempAddress) public {
        require(msg.sender == Seller, "Not the Owner");
        VA_instance = VickreyAuction(TempAddress);
        EndOfBiddingPeriod = now + VA_instance.BiddingTimeRemaining() - 5;
        EndOfRevealingPeriod = EndOfBiddingPeriod + 3;
    }
    ///@notice this function is to place a bid in barbossa brethren auction
    ///@param HashValue has the hash of the bid to be place
    function PlaceBidInBarbossaBrethren(bytes32 HashValue) public {
        require(msg.sender != Seller, "Seller Cannot Bid");
        Auction.PlaceBid(HashValue);
    }
    ///@notice function to reveal the highest bid among the barbossa brethren
    ///@dev compare the amount bidded to the highest bid till now and manipulate the highest bid accordingly
    ///@param BidAmount has the value bidded by a party
    ///@param Nonce has the nonce value stored in it
    function RevealBidInBarbossaBrethren(uint BidAmount, uint Nonce) public {
        Auction.RevealBid(BidAmount, Nonce);
        if (BidAmount > HighestBid) {
            HighestBid = BidAmount;
            HighestBidder = msg.sender;
        }
    }
    ///@notice function to send the highest bid to vickery auction
    
    function SendTheWinningBidToVickreyAuction() public {
        require(msg.sender == Seller, "Not the Owner");
        uint TempNonce = 10;
        VA_instance.PlaceBid(keccak256(abi.encodePacked(HighestBid, TempNonce)));
    }
    ///@notice function to reveal the highest bid here in vickery auction
    function RevealTheWinningBidToVickreyAuction() public {
        require(msg.sender == Seller, "Not the Owner");
        VA_instance.RevealBid(HighestBid, 10);
    }
}