pragma solidity ^0.5.0;

contract Auction {
    address payable public beneficiary;

    // Current state of the auction. You can create more variables if needed
    address public highestBidder;
    uint public highestBid;
    bool isAuctionOver;     // check the auction state

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    // Constructor
    constructor() public {
        beneficiary = msg.sender;
        isAuctionOver = false;
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid() public payable{


        // TODO If the bid is not higher than highestBid, send the
        // money back. Use "require"
        require (msg.sender!=beneficiary, "Beneficiary cannot make a bid for his own auction");
        require (isAuctionOver == false, "Auction already over");
        require (msg.value > highestBid, "Make a higher bid");
        
        // TODO store the previously highest bid in pendingReturns. That bidder
        // will need to trigger withdraw() to get the money back.
        // For example, A bids 5 ETH. Then, B bids 6 ETH and becomes the highest bidder. 
        // Store A and 5 ETH in pendingReturns. 
        // A will need to trigger withdraw() later to get that 5 ETH back.

        pendingReturns[highestBidder] += highestBid;

        // TODO update state

        highestBidder = msg.sender;
        highestBid = msg.value;

        // Sending back the money by simply using
        // highestBidder.send(highestBid) is a security risk
        // because it could execute an untrusted contract.
        // It is always safer to let the recipients
        // withdraw their money themselves.
        
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {
        require(msg.sender!=beneficiary, "Beneficiary cannot call withdraw");
        // TODO send back the amount in pendingReturns to the sender. Try to avoid the reentrancy attack. Return false if there is an error when sending

        uint amt = pendingReturns[msg.sender];
        pendingReturns[msg.sender] = 0;         // to make sure reentrant code doesn't affect the contract

        (bool success, ) = msg.sender.call.value(amt)("");
        if(!success){
            pendingReturns[msg.sender] = amt;
            return false;
        }
        return true;       // sent successfully
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public {
        // TODO make sure that only the beneficiary can trigger this function. Use "require"
        require(msg.sender==beneficiary, "Sender is not beneficiary, Can't end auction");
        require(isAuctionOver==false, "Auction already over");
        isAuctionOver = true;   // to prevent reentrancy, once set to true another execution of the method is not possible.

        // TODO send money to the beneficiary account. Make sure that it can't call this auctionEnd() multiple times to drain money
      
        (bool success, ) = beneficiary.call.value(highestBid)("");
        require(success, "Transfer failed.");
    }
}