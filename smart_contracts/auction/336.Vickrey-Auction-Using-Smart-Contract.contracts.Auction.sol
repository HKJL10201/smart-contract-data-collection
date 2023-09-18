pragma solidity ^0.5.16;

import "./HelperAuction.sol";

///@author Rutwik , Yashwanth , Sunil and Manikanta
///@title Implementation of the Auction(to place,reveal bids and transfer the ether to the seller)

contract Auction is HelperAuction {
    ///@notice function to place a bid.
    ///@param HashValue have the hash value of the bid being placed
    ///@dev the bid should be placed before the end of the bidding period
    function PlaceBid(bytes32 HashValue) public {
        require(now < EndOfBiddingPeriod, "Bidding Time has Ended");
        HashOfBidsPlaced[msg.sender] = HashValue;
    }

    ///@notice function to reveal the bid.
    ///@dev reveal the bids in the duration of the revealing period
    ///@param BidAmount has the value of the amount bidded
    ///@param Nonce has the nonce value

    function RevealBid(uint BidAmount, uint Nonce) public {

        require(now >= EndOfBiddingPeriod,"Revealing Time has not Started");
        require(now < EndOfRevealingPeriod,"Revealing Time has Ended");
        require(keccak256(abi.encodePacked(BidAmount, Nonce)) == HashOfBidsPlaced[msg.sender], "Hash Values Don't Match");
        require(!IsBidRevealed[msg.sender], "Bid has Already Been Revealed");
        IsBidRevealed[msg.sender] = true;
    }

    ///@notice function to transfer the ether
    ///@param receiver has the address of the person that receive the amount paid
    ///@param amount has the value of ether that is going to be transferred
    function TransferEther(address payable receiver, uint amount) payable external {
        require(msg.sender == Seller, "Not the Owner");
        receiver.transfer(amount);
    }
}