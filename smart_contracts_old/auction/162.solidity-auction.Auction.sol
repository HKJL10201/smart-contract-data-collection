// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Auction contract.
 */
contract Auction {
    address payable public owner;
    address payable public highestBidder;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public highestBindingBid;
    uint256 private bidIncrement;
    string public ipfsHash;

    enum State {Started, Running, Ended, Cancelled}
    State public auctionState;

    mapping(address => uint256) public bids;
    mapping(address => bool) public payedBidders;

    constructor(address creator) {
        owner = payable(creator);
        auctionState = State.Running;
        startTime = block.timestamp;
        // @dev The Auctions' end time is 1 week (604800 seconds) after it started.
        endTime = startTime + 604800;
        bidIncrement = 100;
    }

    /**
     * @notice Place a bid for the auction.
     */
    function placeBid() public payable {
        /// @dev Don't let owner bid so that it can't artificially increase the price.
        require(msg.sender != owner);
        /// @dev Check that the auction is active.
        require(block.timestamp >= startTime, "Auction isn't active");
        require(block.timestamp <= endTime, "Auction isn't active");
        require(auctionState == State.Running, "Auction isn't active");

        require(msg.value >= bidIncrement, "Bid too small");

        uint256 currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid, "Bid too small");

        bids[msg.sender] = currentBid;

        if (currentBid <= bids[highestBidder]) {
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else {
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }

    /**
     * @notice Cancels the auction. Only the owner can do this.
     */
    function cancelAuction() public {
        require(msg.sender == owner);
        auctionState = State.Cancelled;
    }

    /**
     * @notice Allows bidders to retrieve their money if the auction finishes or is cancelled. Only the owner or bidders can do this.
     */
    function afterAuction() public {
        require(auctionState == State.Cancelled || block.timestamp > endTime, "Auction not over nor cancelled");
        require(payedBidders[msg.sender] == false, "Funds already claimed");
        require(msg.sender == owner || bids[msg.sender] > 0, "Not a participating address");

        address payable recipient;
        uint256 value;

        if (auctionState == State.Cancelled) {
            // The auction was cancelled and bidders can retrieve their money.
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            // The auction ended.
            if (msg.sender == owner) {
                // The owner can retrieve the money from the sale.
                recipient = owner;
                value = highestBindingBid;
            } else {
                if (msg.sender == highestBidder) {
                    // The highest bidder can retrieve the difference between the value he bid and the highestBindingBid.
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else {
                    // Bidders that didn't win the auction can retrieve their funds.
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        payedBidders[msg.sender] = true;
        recipient.transfer(value);
    }

    /**
     * @dev Returns the minimum of two values.
     * @param x First value
     * @param y Second value
     * @return The minimum of the two values.
     */
    function min(uint256 x, uint256 y) private pure returns (uint256) {
        if (x <= y) {
            return x;
        }
        return y;
    }
}
