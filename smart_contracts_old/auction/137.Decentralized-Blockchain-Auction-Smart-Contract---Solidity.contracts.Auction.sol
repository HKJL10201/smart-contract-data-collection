pragma solidity ^0.5.0;

contract Auction {
    address payable public beneficiary;
    //uint public auctionEndTime;
    // Current state of the auction. You can create more variables if needed
    address public highestBidder;
    uint public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;
    bool auctionEnded;
    bool wdFlag;

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
        require(
           msg.value > highestBid,
           "A higher bid is placed !"
        );


        // TODO update state

        // TODO store the previously highest bid in pendingReturns. That bidder
        // will need to trigger withdraw() to get the money back.
        // For example, A bids 5 ETH. Then, B bids 6 ETH and becomes the highest bidder.
        // Store A and 5 ETH in pendingReturns.
        // A will need to trigger withdraw() later to get that 5 ETH back.
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        wdFlag = true; // This flag is used for a withdraw() function check.
        // Sending back the money by simply using
        // highestBidder.send(highestBid) is a security risk
        // because it could execute an untrusted contract.
        // It is always safer to let the recipients
        // withdraw their money themselves.

    }

    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {

        require(wdFlag, "There is no bid placed!"); // If there is no bid placed then there cannot be a withdraw() call
        // TODO send back the amount in pendingReturns to the sender. Try to avoid the reentrancy attack. Return false if there is an error when sending
        uint bidRefund = pendingReturns[msg.sender];
        if (bidRefund > 0) {
         pendingReturns[msg.sender] = 0; // This is set to zero to make sure the receiver doesnt call this function before a send is returned
         if (!msg.sender.send(bidRefund)) {
                pendingReturns[msg.sender] = bidRefund;
                return false;
            }
        }
        return true;

     }
    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public {
        // TODO make sure that only the beneficiary can trigger this function. Use "require"
        //require(now >= auctionEndTime, "Auction hasn’t ended yet.");
        require(!auctionEnded, "auctionEnd has already been called.");
        require(beneficiary == msg.sender, "Auction can be closed only by beneficiary");
        auctionEnded = true;
        beneficiary.transfer(highestBid);
        // TODO send money to the beneficiary account. Make sure that it can't call this auctionEnd() multiple times to drain money
    }
}
