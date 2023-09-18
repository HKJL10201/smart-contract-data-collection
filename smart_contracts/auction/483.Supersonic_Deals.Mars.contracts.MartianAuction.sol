pragma solidity >=0.4.22 <0.7.0;

/* 
Taken straight from the Solidity docs
https://solidity.readthedocs.io/en/v0.5.10/solidity-by-example.html?highlight=auction#id2
you must modify this to be compatible with the MartianMarket contract
Source: https://columbia.bootcampcontent.com/columbia-bootcamp/CU-NYC-FIN-PT-12-2019-U-C/blob/master/22-DeFi/3/Activities/03-Stu_Writing_an_Auction_Contract/Solved/MartianAuction.sol
*/

contract MartianAuction {
    // Parameters of the auction. Times are either
    // absolute unix timestamps (seconds since 1970-01-01)
    // or time periods in seconds.
    address payable public beneficiary;
    // Remove biddingTime functionality so that foundation may call at any time
    /*uint public auctionEndTime;*/

    // Current state of the auction.
    address public highestBidder;
    uint public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    // Set `ended` as a PUBLIC variable.
    bool public ended;

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // The following is a so-called natspec comment,
    // recognizable by the three slashes.
    // It will be shown when the user is asked to
    // confirm a transaction.

    /// Create a simple auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_beneficiary`.
    constructor(
        /*uint _biddingTime,*/
        address payable _beneficiary
    ) public {
        beneficiary = _beneficiary;
        /*auctionEndTime = now + _biddingTime;*/
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid(address payable sender) public payable {
        // No arguments are necessary, all
        // information is already part of
        // the transaction. The keyword payable
        // is required for the function to
        // be able to receive Ether.

        // Revert the call if the bidding
        // period is over.

        /*require(
            now <= auctionEndTime,
            "Auction already ended."
        );*/

        // If the bid is not higher, send the
        // money back.
        require(
            msg.value > highestBid,
            "Someone offers a higher bid! Would you like to raise yours?"
        );

        require(!ended, "Oops. The auction has ended. See you next round!");
        // only allows the beneficiary to end the auction
        require(msg.sender == beneficiary, "Become a beneficiary to be authorized.");

        if (highestBid != 0) {
            // Sending back the money by simply using
            // highestBidder.send(highestBid) is a security risk
            // because it could execute an untrusted contract.
            // It is always safer to let the recipients
            // withdraw their money themselves.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = sender;
        highestBid = msg.value;
        emit HighestBidIncreased(sender, msg.value);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function pendingReturn(address sender) public view returns (uint) {
        return pendingReturns[sender];
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public {
        // It is a good guideline to structure functions that interact
        // with other contracts (i.e. they call functions or send Ether)
        // into three phases:
        // 1. checking conditions
        // 2. performing actions (potentially changing conditions)
        // 3. interacting with other contracts
        // If these phases are mixed up, the other contract could call
        // back into the current contract and modify the state or cause
        // effects (ether payout) to be performed multiple times.
        // If functions called internally include interaction with external
        // contracts, they also have to be considered interaction with
        // external contracts.

        // 1. Conditions
        /*require(now >= auctionEndTime, "Auction not yet ended.");*/
        require(!ended, "Oops. The auction has ended. See you next round!");
        // only allows the beneficiary to end the auction
        require(msg.sender == beneficiary, "Become a beneficiary to be authorized.");

        // 2. Effects
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. Interaction
        beneficiary.transfer(highestBid);
    }
}
