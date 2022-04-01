pragma solidity ^0.5.0;

contract Auction {
    address payable public beneficiary;

    // Current state of the auction. You can create more variables if needed
    address public highestBidder;
    uint public highestBid;
    bool public auctionEndedMoneyWithdrawn = false;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    // Constructor
    constructor() public {
        beneficiary = msg.sender;
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid() public payable {


        // TODO If the bid is not higher than highestBid, send the
        // money back. Use "require"
        require(msg.value > highestBid, "Current bid is less than the highest bid");
        require(auctionEndedMoneyWithdrawn == false, "The auction already ended.");

        pendingReturns[highestBidder] = highestBid;

        // TODO update state
        highestBid = msg.value;
        highestBidder = msg.sender;

        // TODO store the previously highest bid in pendingReturns. That bidder
        // will need to trigger withdraw() to get the money back.
        // For example, A bids 5 ETH. Then, B bids 6 ETH and becomes the highest bidder.
        // Store A and 5 ETH in pendingReturns.
        // A will need to trigger withdraw() later to get that 5 ETH back.



        // Sending back the money by simply using
        // highestBidder.send(highestBid) is a security risk
        // because it could execute an untrusted contract.
        // It is always safer to let the recipients
        // withdraw their money themselves.

    }

    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {

        // TODO send back the amount in pendingReturns to the sender. Try to avoid the reentrancy attack. Return false if there is an error when sending
        require(pendingReturns[msg.sender] > 0, "Bidder has already withdrawn.");
        require(msg.sender != highestBidder, "Highest bidder cannot withdraw.");
        uint withdrawableAmount = pendingReturns[msg.sender];
        pendingReturns[msg.sender] = 0;
        msg.sender.transfer(withdrawableAmount);
        return true;
        // Delete the mapping element after withdrawal.
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public {
        // Only the beneficiary can trigger this function. Use "require"
        require(msg.sender == beneficiary, "Only the beneficiary can end the auction.");
        // Beneficiary can't call this auctionEnd() multiple times to drain money
        require(auctionEndedMoneyWithdrawn == false, "The auction already ended and money has been withdrawn by the beneficiary.");
        auctionEndedMoneyWithdrawn = true;


        //TODO send money to the beneficiary account. Make sure that it can't call this auctionEnd() multiple times to drain money

        // Final transfer
        msg.sender.transfer(highestBid);
    }
}
