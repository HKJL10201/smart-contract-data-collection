// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/**
 * Blind auction allows bidding within an allotted time.
 * Bids can be faked to gain advantage over others.
 */
contract BlindAuction {
    address payable public beneficiary;
    address public highestBidder;
    uint256 public highestBid;
    // time period for the bids
    uint256 public biddingEnd;
    // time bids can be revealed
    uint256 public revealEnd;
    bool public ended;

    struct Bid {
        bytes32 blindedBid;
        uint256 deposit;
    }
    // allowed withdrawals of previous bids
    mapping(address => uint256) public pendingReturns;
    mapping(address => Bid[]) public bids;

    event AuctionEnded(address winner, uint256 highestBid);
    event Refund(address recipient, uint256 refund);
    event BidIndex(uint256 index);
    event Withdraw(uint256 amount);

    /// Called too early. Try later at `time`.
    error TooEarly(uint256 time);
    /// Called too late.
    error TooLate(uint256 time);
    /// Called already.
    error AuctionEndAlreadyCalled();
    /// Unmatched length.
    error UnmatchedLength();

    modifier onlyBefore(uint256 time) {
        if (block.timestamp >= time) revert TooLate(time);
        _;
    }

    modifier onlyAfter(uint256 time) {
        if (block.timestamp <= time) revert TooEarly(time);
        _;
    }

    /**
     * Initialize the smart contract
     * @param biddingTime period in seconds
     * @param revealTime period in seconds after the bidding ended
     * @param beneficiaryAddress receives the highest bid after the bidding ends.
     */
    constructor(
        uint256 biddingTime,
        uint256 revealTime,
        address payable beneficiaryAddress
    ) {
        beneficiary = beneficiaryAddress;
        biddingEnd = block.timestamp + biddingTime;
        revealEnd = biddingEnd + revealTime;
    }

    function placeBid(address bidder, uint256 value)
        internal
        returns (bool success)
    {
        if (value <= highestBid) return false;
        // first time, highestBidder is initialized by default to 0 address
        if (highestBidder != address(0))
            // accumulate previous highest bid by same bidder
            pendingReturns[highestBidder] += highestBid;

        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    function createBlindedBid(
        uint256 value,
        bool fake,
        bytes32 secret
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(value, fake, secret));
    }

    /**
     * Place a blinded bid with
     * `blindedBid` = keccak256(abi.encodePacked(value, fake, secret)).
     * The sent ether is only refunded if the bid is correctly revealed in the
     * revealing phase. The bid is valid if the ether sent together with the bid
     * is at least "value" and "fake" is not true. Setting "fake" to true and
     * sending not the exact amount are ways to hide the real bid but still
     * make the required deposit. The same address can make multiple bids.
     */
    function bid(bytes32 blindedBid) external payable onlyBefore(biddingEnd) {
        bids[msg.sender].push(
            Bid({blindedBid: blindedBid, deposit: msg.value})
        );
        emit BidIndex(bids[msg.sender].length - 1);
    }

    /**
     * Reveal your bids. You will get a refund for all correctly blinded
     * invalid bids and for all bids except for the totally highest.
     * @param values list of bid amount in the same order when bid was added.
     * @param fakes list of flags in the same order indicating the real or fake bids when bid was added.
     * @param secrets list of secrets attached in the same order when the bid was added.
     */
    function reveal(
        uint256[] calldata values,
        bool[] calldata fakes,
        bytes32[] calldata secrets
    ) external onlyAfter(biddingEnd) onlyBefore(revealEnd) {
        uint256 length = bids[msg.sender].length;
        if (
            values.length != length &&
            fakes.length != length &&
            secrets.length != length
        ) revert UnmatchedLength();

        uint256 refund;
        for (uint256 i = 0; i < length; i++) {
            Bid storage bidToCheck = bids[msg.sender][i];

            (uint256 value, bool fake, bytes32 secret) = (
                values[i],
                fakes[i],
                secrets[i]
            );

            // verify the hash and skip invalid bid hash
            if (
                bidToCheck.blindedBid !=
                keccak256(abi.encodePacked(value, fake, secret))
            ) {
                // Bid was not actually revealed.
                // Do not refund deposit and continue to next iteration.
                continue;
            }

            // from here the bid is valid so add up refunds
            refund += bidToCheck.deposit;

            if (!fake && bidToCheck.deposit >= value) {
                // place real bid and deduct from accumulated refund
                if (placeBid(msg.sender, value)) refund -= value;
            }
            // Make it impossible for the sender to re-claim the same deposit.
            bidToCheck.blindedBid = bytes32(0);
        }
        payable(msg.sender).transfer(refund);
        emit Refund(msg.sender, refund);
    }

    // Withdraw a bid that was overbid.
    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient can
            // call this function again as part of the receiving call before
            // `transfer` returns.
            // Ref: conditions -> effects -> interaction
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
        emit Withdraw(amount);
    }

    // End the auction and send the highest bid to the beneficiary.
    function auctionEnd() external onlyAfter(revealEnd) {
        if (ended) revert AuctionEndAlreadyCalled();
        emit AuctionEnded(highestBidder, highestBid);
        // end early to avoid re-entrancy
        ended = true;

        beneficiary.transfer(highestBid);
    }
}
