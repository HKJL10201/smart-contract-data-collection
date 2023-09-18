// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract SimpleAuction {
    // Parameters of the auction. Times are either
    // absolute unix timestamps (seconds since 1970-01-01)
    // or time periods in seconds.
    address payable public beneficiary;
    address public owner;
    uint256 public auctionEndTime;
    // Current state of the auction.
    address public highestBidder;
    uint256 public highestBid;
    address[] public listBidders;
    // Keeping track of how much someone bade 
    mapping(address => uint256) public pendingReturns;
    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool public ended;
    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint256 amount);
    event HighestBidDecreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    // Errors that describe failures.
    // The triple-slash comments are so-called natspec
    // comments. They will be shown when the user
    // is asked to confirm a transaction or
    // when an error is displayed.
    /// The auction has already ended.
    error AuctionAlreadyEnded();
    /// There is already a higher or equal bid.
    error BidNotHighEnough(uint256 highestBid);
    /// The auction has not ended yet.
    error AuctionNotYetEnded();
    /// The function auctionEnd has already been called.
    error AuctionEndAlreadyCalled();

    /// Create a simple auction with `biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `beneficiaryAddress`.
    /// You can either delegate your self as both
    /// beneficiary and owner, or you can delegate another
    /// address as the beneficiary
    constructor(uint256 biddingTime, address payable beneficiaryAddress) {
        owner = msg.sender;
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid() external payable {
        // No arguments are necessary, all
        // information is already part of
        // the transaction. The keyword payable
        // is required for the function to
        // be able to receive Ether.
        // Revert the call if the bidding
        // period is over.
        if (block.timestamp > auctionEndTime) revert AuctionAlreadyEnded();
        // If the bid is not higher, send the
        // money back (the revert statement
        // will revert all changes in this
        // function execution including
        // it having received the money).
        if (msg.value <= highestBid) revert BidNotHighEnough(highestBid);
        // If the bid is higher, add the sender
        // and the value to the mappings.
        // Change the highestBidder to the new bidder,
        // and the highestBid to the new value.
        // Also add the address to the list of
        // addresses that bade.
        if (msg.value > highestBid) {
            pendingReturns[msg.sender] = msg.value;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
        listBidders.push(msg.sender);
    }

    /// Withdraw a bid that was overbid, or
    /// a bid that is not "in competiotion" anymore.
    /// E.g. i bade 0.1eth and somebody else bade 0.2eth,
    /// i can withdraw my 0.1eth.
    function withdraw() external {
        require(
            pendingReturns[msg.sender] != 0,
            "You either didn't bid or you already withdrawed"
        );
        if (ended) revert AuctionEndAlreadyCalled();
        // This keeps track of the highest bid
        uint256 newHighestBid = 0;
        // It is important to set the pendingReturn to zero because the recipient
        // can call this function again as part of the receiving call
        // before `.call` returns.
        // msg.sender is not of type `address payable` and must be
        // explicitly converted using `.call`
        (bool success, ) = msg.sender.call{value: pendingReturns[msg.sender]}(
            ""
        );
        require(success, "Call failed");
        pendingReturns[msg.sender] = 0;
        // In case the address that withdraw was the
        // highest bidder, this section of the code
        // will find the new highest bidder and it will
        // emit the change
        if (msg.sender == highestBidder) {
            highestBid = 0;
            highestBidder = address(0);
            // This loop is needed in order to get
            // The new highestBid and highestBidder
            for (uint256 i = 0; i < listBidders.length; i++) {
                if (pendingReturns[listBidders[i]] > newHighestBid) {
                    newHighestBid = pendingReturns[listBidders[i]];
                    highestBid = newHighestBid;
                    highestBidder = listBidders[i];
                }
            }
            emit HighestBidDecreased(highestBidder, highestBid);
        }
    }

    /// End the auction, send the highest bid
    /// to the beneficiary, and the pending returns
    /// in case there are any. Only the "deployer" of
    /// the contract can call this function
    function auctionEnd() external {
        require(msg.sender == owner);
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
        if (block.timestamp < auctionEndTime) revert AuctionNotYetEnded();
        if (ended) revert AuctionEndAlreadyCalled();
        // 2. Effects
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        // 3. Interaction
        if (highestBid != 0) {
            beneficiary.transfer(highestBid);
            pendingReturns[highestBidder] = 0;
            highestBid = 0;
            highestBidder = address(0);
            for (uint256 x = 0; x < listBidders.length; x++) {
                if (pendingReturns[listBidders[x]] != 0) {
                    (bool successs, ) = listBidders[x].call{
                        value: pendingReturns[listBidders[x]]
                    }("");
                    require(successs);
                    pendingReturns[listBidders[x]] = 0;
                }
            }
        }
    }
}
