// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract AuctionCreator {
    Auction[] public auctions;

    function createAuction() public {
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

contract Auction {
    address payable public owner;
    uint256 public startBlock;
    uint256 public endBlock;
    string public ipfsHash;

    enum State {
        Started,
        Running,
        Ended,
        Cancelled
    }
    State public auctionState;

    uint256 public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint256) public bids;
    uint256 bidIncrement;

    // The owner can finalize the auction and get the highestBindingBid only once
    bool public ownerFinalized = false;

    constructor(address eoa) {
        owner = payable(eoa);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 40320; // The auction will be running for a week
        ipfsHash = "";
        bidIncrement = 1000000000000000000; // Bidding in multiple of ETH
    }

    // The owner cannot place bids on their own auction to increase the price artificially
    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Helper pure function, it neither reads, nor writes to the blockchain
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    // Only the owner can cancel the Auction before the Auction has ended
    function cancelAuction() public onlyOwner {
        auctionState = State.Cancelled;
    }

    // Main function to place a bid
    function placeBid()
        public
        payable
        notOwner
        afterStart
        beforeEnd
        returns (bool)
    {
        // To place a bid, the auction should be running
        require(auctionState == State.Running);
        // Minimun value allowed to be sent
        require(msg.value > 0.0001 ether);

        uint256 currentBid = bids[msg.sender] + msg.value;

        // The currentBid should be greater than the highestBindingBid
        // Otherwise, it does nothing
        require(currentBid > highestBindingBid);

        // Updating the mapping variable
        bids[msg.sender] = currentBid;

        if (currentBid <= bids[highestBidder]) {
            // HighestBidder remains unchanged
            highestBindingBid = min(
                currentBid + bidIncrement,
                bids[highestBidder]
            );
        } else {
            // highestBidder is another bidder
            highestBindingBid = min(
                currentBid,
                bids[highestBidder] + bidIncrement
            );
            highestBidder = payable(msg.sender);
        }
        return true;
    }

    function finalizeAuction() public {
        // The auction has been cancelled or ended
        require(auctionState == State.Cancelled || block.number > endBlock);
        // Only the owner or a bidder can finalize the auction
        require(msg.sender == owner || bids[msg.sender] > 0);

        // The recipient will get the value
        address payable recipient;
        uint256 value;

        if (auctionState == State.Cancelled) {
            // Auction was cancelled, not ended
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            // Auction ended, not canceled
            if (msg.sender == owner && ownerFinalized == false) {
                // The owner finalizes the auction
                recipient = owner;
                value = highestBindingBid;

                // The owner can finalize the auction and get the hoghestBindingBid only once
                ownerFinalized = true;
            } else {
                // Another user (not the owner) finalizes the auction
                if (msg.sender == highestBidder) {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else {
                    // This is neither the owner nor the highestBidder, just a regular bidder
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        // Resetting the bids of the recipient to avoid multiple transfers to the same recipient
        bids[recipient] = 0;

        // Sends value to the recipient
        recipient.transfer(value);
    }
}
