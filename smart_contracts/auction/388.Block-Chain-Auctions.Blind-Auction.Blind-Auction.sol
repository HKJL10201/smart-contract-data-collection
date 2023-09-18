pragma solidity ^0.4.0;

/* The previous open auction is extended to a blind auction in the following. 
The advantage of a blind auction is that there is no time pressure towards the end of the bidding period. 
Creating a blind auction on a transparent computing platform might sound like a contradiction, but cryptography comes to the rescue.

During the bidding period, a bidder does not actually send her bid, but only a hashed version of it. 
Since it is currently considered practically impossible to find two (sufficiently long) values whose hash values are equal, the bidder commits to the bid by that. 
After the end of the bidding period, the bidders have to reveal their bids: They send their values unencrypted and the contract checks that the hash value is the same as the one provided during the bidding period.

Another challenge is how to make the auction binding and blind at the same time: The only way to prevent the bidder from just not sending the money after he won the auction is to make him send it together with the bid. Since value transfers cannot be blinded in Ethereum, anyone can see the value.

The following contract solves this problem by accepting any value that is at least as large as the bid. Since this can of course only be checked during the reveal phase, some bids might be invalid, and this is on purpose (it even provides an explicit flag to place invalid bids with high value transfers): Bidders can confuse competition by placing several high or low invalid bids. */

contract BlindAuction {
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    address public beneficiary;
    uint public auctionStart;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;

    mapping(address => Bid[]) public bids;

    address public highestBidder;
    uint public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    event AuctionEnded(address winner, uint highestBid);

    /// Modifiers are a convenient way to validate inputs to functions.
    /// `onlyBefore` is applied to `bid` below: 
    /// The new function body is the modifier's body where 
    /// `_` is replaced by the old function body.
    modifier onlyBefore(uint _time) { if (now >= _time) throw; _; }
    modifier onlyAfter(uint _time) { if (now <= _time) throw; _; }

    function BlindAuction(
        uint _biddingTime,
        uint _revealTime,
        address _beneficiary
    ) {
        beneficiary = _beneficiary; // same this.beneficiary = beneficiary in                              tradiotional OOP languages
        auctionStart = now;
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
    }

    /// Place a blinded bid with `_blindedBid` = keccaka256(value, fake, secret).
    /// The sent ether is only refunded if the bif is correctly revealeed in the revealing phase.
    /// The bid is valid if the ehter sent together with the bid is at least "value" and "fake" is not true. Setting "fake" to true and sending not the exact amount are ways to hide the real bid but still make the required deposit.
    /// The same address can place multiple bids.
    function bid(bytes32 _blindedBid) payable onlyBefore(biddingEnd) {
        bids[msg.sender].push(Bid({
            blindedBid: _blindedBid,
            deposit: msg.value
        }));
    }

    /// Reveal your blinded bids. 
    /// You will get a refund for all correctly blinded invalid bids and for all bids except for the totally highest.
    function reveal(
        uint[] _values,
        bool[] _fake,
        bytes32[] _secret
    ) 
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
    {
        uint length = bids[msg.sender].length;
        if (
            _values.length != length || 
            _fake.length != length || 
            _secret.length != length
        ) {
            throw;
        }
        
        uint refund;
        for (uint i = 0; i < length; i++) {
            var bid = bids[msg.sender][i];
            var (value, fake, secret) = 
                    (_values[i], _fake[i], _secret[i]);
            if (bid.blindedBid !=  keccak256(value, fake, secret)) {
                // Bid was not actually revealed.
                // Do not refund deposit.
                continue;
            }
            refund += bid.deposit;
            if (!fake && bid.deposit >= value) {
                if (placeBid(msg.sender, value)) 
                    refund -= value;
            }
            // Make it impossible for the sender to re-claim the same deposit.
            bid.blindedBid = 0;
        }
        if (!msg.sender.send(refund)
            throw;
    }

    // This is an "internal" function which means tha tit can only be called from the contract itself (or from derived contracts).
    function placeBid(address bidder, uint value) internal 
        returns (bool success) 
    {
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != 0) {
            // Refund the previously highest bidder.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    // Withdraw a bid that was overbid.
    function withdaraw() return (bool) {
        var amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient can call this function again as part of the receiving call before `send` returns (see the remark about conditions -> effects -> interaction in SimpleOpenAuction.sol).
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
    function auctionEnd() onlyAfter(revealEnd) {
        if (ended)
            throw;
        AuctionEnded(highestBidder, highestBid);
        ended = true;
        // We send all the money we have, because some of the refunds might have failed.
        if (!beneficiary.send(this.balance))
            throw;
    }
}
