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
        Canceled
    }
    State public auctionState;

    uint256 public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint256) public bids;

    uint256 bidIncrement;

    constructor(address eoa) {
        owner = payable(eoa);

        auctionState = State.Running;

        startBlock = block.number;
        endBlock = startBlock + 40320; // this calculates that the auction will run for a week
        // considering there is avg 1 block each 15s, we divided the number of seconds in a weeb by 15s.

        ipfsHash = "";
        bidIncrement = 100;
    }

    modifier authorizeOwner() {
        require(owner == msg.sender, "UNAUTHORIZED");
        _;
    }

    modifier unauthorizeOwner() {
        require(owner != msg.sender, "OWNER_UNAUTHORIZED");
        _;
    }

    modifier validateDate() {
        require(block.number >= startBlock);
        require(block.number <= endBlock);
        _;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        }
        return b;
    }

    function cancelAuction() public authorizeOwner {
        auctionState = State.Canceled;
    }

    function placeBid() external payable unauthorizeOwner validateDate {
        require(auctionState == State.Running, "AUCTION_NOT_RUNNING");
        require(msg.value >= 100, "MINIMUM_BID_IS_100_WEI");

        uint256 currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid, "MUST_BE_HIGHEST_BID");

        bids[msg.sender] = currentBid;

        if (currentBid <= bids[highestBidder]) {
            highestBindingBid = min(
                currentBid + bidIncrement,
                bids[highestBidder]
            );
        } else {
            highestBindingBid = min(
                currentBid,
                bids[highestBidder] + bidIncrement
            );
            highestBidder = payable(msg.sender);
        }
    }

    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0); //owner or bidder can finalize

        address payable recipient;
        uint256 value;

        if (auctionState == State.Canceled) {
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            if (msg.sender == owner) {
                recipient = owner;
                value = highestBindingBid;
            } else {
                if (msg.sender == highestBidder) {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else {
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        bids[recipient] = 0;
        recipient.transfer(value);
    }
}
