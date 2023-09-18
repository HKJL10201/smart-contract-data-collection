// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.0;

contract SimpleAuction {
    address payable public beneficiary;
    uint public auctionEndTime;
    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) pendingReturns;
    bool ended;
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    /// The auction has already ended.
    error AuctionAlreadyEnded();
    /// There is already a higher or equal bid.
    error BidNotHighEnough(uint highestBid);
    /// The auction has not ended yet.@author
    error AuctionNotYetEnded();
    /// The auctionend has already called

    /// Create a simple auction with `biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `beneficiaryAddress`.
    function SimpleAuction(uint biddingTime, address payable beneficiaryAddress){
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
    }
    /// Bid on the auction with the value
    /// The value will be refunded if the auction is not won
    function bid() external  payable {
        // The keyword payable is required for the function to be able to receive Ether
        // Revert the call if the bidding is over, and gave back the unused gas to the caller
        if (block.timestamp > auctionEndTime)
            revert AuctionAlreadyEnded();

        // If the bid is not higher, send the money back to caller
        // The revert statement will revert all changes in this function
        if (msg.sender <= highestBid)
            revert BidNotHighEnough(highestBid);

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = msg.value;
        highestBidder = msg.sender;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// Withdraw a bid that was overbid
    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// End the auction and send the highest bid
    /// to the beneficiary
    function auctionEnd() external {
        ///1. Check condition
        ///2. Perform actions
        ///3. Interact with other contracts
        //1. Conditions
        if (block.timestamp < auctionEndTime)
            revert AuctionNotYetEnded();
        if (ended)
            revert AuctionEndAlreadyCalled();

        //2. Effects
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        //3. Interaction
        beneficiary.transfer(highestBid);
    }
}
