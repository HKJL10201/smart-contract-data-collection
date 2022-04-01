// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.4;

/// @title Auction
/// @author Edgar Herrador
/// @notice You can use this contract like a seller to create an auction or like a Purchaser to put a bid
/// @dev All functions are currently implemented for Proof of Conpcept scenarios
contract Auction {
    // Parameters of the auction. Times are either
    // absolute unix timestamps (seconds since 1970-01-01)
    // or time periods in seconds.
    address public beneficiary;
    uint public auctionEndTime;
    uint public currentPrice;
    uint priceForBuyNow;
    uint orderNumber;
    uint initialVoucherId;
    uint finalVoucherId;

    // Current state of the auction.
    address public highestBidder;
    uint public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;
    mapping(address => uint) bidders;

    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool ended;

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(uint orderNumber, uint initialVoucherId, uint finalVoucherId, address winner, uint amount);
    event OrderBuyed(uint orderNumber, uint initialVoucherId, uint finalVoucherId, address buyer, uint amount);

    // Errors that describe failures.

    // The triple-slash comments are so-called natspec
    // comments. They will be shown when the user
    // is asked to confirm a transaction or
    // when an error is displayed.

    /// The auction has already ended.
    error AuctionAlreadyEnded();
    /// There is already a higher or equal bid.
    error BidNotHighEnough(uint highestBid);
    /// The auction has not ended yet.
    error AuctionNotYetEnded();
    /// The function auctionEnd has already been called.
    error AuctionEndAlreadyCalled();
    /// The value proposed to buy now is not enough
    error AmountToBuyNowNotEnough();

    modifier onlyBeneficiary() {
        require(beneficiary == msg.sender, "the caller is not the beneficiary");
        _;
    }

    /// Create a simple auction with `biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `beneficiaryAddress`.
    constructor(
        uint numberOfOrder,
        uint initialId,
        uint finalId,
        uint orderPrice,
        uint buyNowPrice,
        uint biddingTime
    ) {
        beneficiary = msg.sender;
        currentPrice = orderPrice;
        highestBidder = address(0);
        highestBid = 0;
        priceForBuyNow = buyNowPrice;
        auctionEndTime = block.timestamp + biddingTime;
        orderNumber = numberOfOrder;
        initialVoucherId = initialId;
        finalVoucherId = finalId;
    }

    function getHighestBid() public view returns(uint) {
        return highestBid;
    }

    function getHighestBidder() public view returns(address) {
        return highestBidder;
    }

    function getBuyNowPrice() public view returns(uint) {
        return priceForBuyNow;
    }

    function getAuctionEndTime() public view returns(uint) {
        return auctionEndTime;
    }

    function getBlockTimestamp() public view returns(uint) {
        return block.timestamp;
    }

    function buyNow(uint amount) public {
         if (ended)
            revert AuctionAlreadyEnded();

        // Revert the call if the bidding period is over.
        if (block.timestamp > auctionEndTime)
            revert AuctionAlreadyEnded();
        
        if (amount < priceForBuyNow) 
            revert AmountToBuyNowNotEnough();

        bidders[highestBidder] += highestBid;
        highestBidder = msg.sender;
        highestBid = amount;

        ended = true;
        emit OrderBuyed(orderNumber, initialVoucherId, finalVoucherId, highestBidder, highestBid);
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid(uint valueBid) external {
        if (ended)
            revert AuctionAlreadyEnded();

        // Revert the call if the bidding period is over.
        if (block.timestamp > auctionEndTime)
            revert AuctionAlreadyEnded();
        
        if (highestBid == 0)
            if (valueBid < currentPrice)
                revert BidNotHighEnough(highestBid);
        
        if (valueBid <= highestBid) 
            revert BidNotHighEnough(highestBid);

        /*if (highestBid != 0) {
            // Sending back the money by simply using highestBidder.send(highestBid) is a security risk
            // because it could execute an untrusted contract.
            // It is always safer to let the recipients withdraw their money themselves.

            pendingReturns[highestBidder] += highestBid;
        }*/

        bidders[highestBidder] += highestBid;
        highestBidder = msg.sender;
        highestBid = valueBid; 
        emit HighestBidIncreased(msg.sender, valueBid); //msg.value);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public onlyBeneficiary {
        // 1. Conditions
        if (block.timestamp < auctionEndTime)
            revert AuctionNotYetEnded();
        if (ended)
            revert AuctionEndAlreadyCalled();

        // 2. Effects
        ended = true;
        emit AuctionEnded(orderNumber, initialVoucherId, finalVoucherId, highestBidder, highestBid);

        // 3. Interaction
        //beneficiary.transfer(highestBid);
    }
}