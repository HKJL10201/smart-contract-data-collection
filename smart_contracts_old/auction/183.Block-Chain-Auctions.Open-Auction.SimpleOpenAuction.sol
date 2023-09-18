pragma solidity ^0.4.0;

/* The general idea od the following simple auction contract is that everyone can send their bids during a bidding period. The bids already include sending money / ether in order to bind the bidders to their bid.If the highest bid is raised, the previously highest bidder gets her money back. After the end of the bidding period, the contract has to be called manually for the beneficiary to receive his money - contracts cannot activate themselves. */

contract SimpleAuction {
    /* Paramaters of the auction. 
    Times are either absolute unix timestamps (seconds since 1970-01-01)
    or time periods in seconds. */
    address public beneficiary;
    uint public auctionStart;
    uint public biddingTime;

    // Current state of the auction.
    address public highestBidder;
    uint public highestBid;

    // Allowed withdrawals of previous bids.
    mapping (address => uint) pendingRetuns;

    // Set to true at the end, disallows any change.
    bool ended;

    // Events that will be fired on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    /* The following is a so-called natspec comment, recognizable by the three slashes. It will be shown wehn the user is asked to confirm a transaction. */

    /// Crate a simple auction with `_biddingTime` 
    /// seconds bidding time on behalf of the 
    /// beneficiary address `_beneficiary`
    function SimpleAuction(uint _biddingTime, address _beneficiary) {
        beneficiary = _beneficiary;
        auctionStart = now;
        biddingTime = _biddingTime;
    }

    /// Bid on the auction with the value sent together with this transaction.
    /// The value will only be refunded if the auction is not won.
    function bid() payable {
        if (now > auctionStart + biddingTime) {
            // Revert the call if the bidding period is over.
            throw;
        }
        if (msg.value <= highestBid) {
            // If the bid is not higher, send the money back.
            throw;
        }
        if(highestBidder != 0) {
            /* Sending the money back by simply using highestBidder.send(highestBid) is a security risk because it can be prevented by the caller by e.g. raising the call stack to 1023.
            It is always safer to let the recipient withdraw their money themselves. */
            pendingRetuns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        HighestBidIncreased(msg.sender, msg.value);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() returns (bool) {
        var amount = pendingRetuns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient can call this function again as part of the recieving call before 'send' returns.
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                // No need to call throw here, just reset the amount owing.
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // End of the auction and send the highest bid to the beneficiary.
    function auctionEnd() {
        /* It is a good guideline to structure functions that interact with other contracts (i.e., they call functions or send Ether) into three phases: 
        1. checking conditions
        2. performing actions (potentially changing conditions)
        3. interacting with other contracts
        If these phases are mixed up, the other contract could call back into the current contract and modify the state or cause effects (ether payout) to the performed multiple times.
        If functions called internally include interaction with external contracts, they also have to be considered interaction with external contracts. */

        // 1. Conditins
        if (now <= auctionStart + biddingTime) 
            throw; // auction did not end yet
        if (ended)
            throw; // this function has already been called.
        
        // 2. Effects 
        ended = true;
        AuctionEnded(highestBidder, highestBid);

        // 3. interaction
        if (!beneficiary.send(highestBid))
            throw;
    }

}