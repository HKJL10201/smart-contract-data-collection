// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import {IERC721} from "./IERC721.sol";

contract NFT_Auction {
    address public immutable seller;
    address public immutable owner;

    bool public ended;
    bool public started;
    uint public endAt;

    uint public highestBid;
    address public highestBidder;

    mapping(address => uint) public bids;

    // NFT parameters
    IERC721 public immutable nft;
    uint public immutable nftid;

    //events
    event AuctionStarted();
    event AuctionEnded(address highestBidder, uint highestBid);
    event BidPlaced(address indexed bidder, uint amount);
    event Withdrawn(address indexed bidder, uint amount);

    constructor(address _seller, IERC721 _nft, uint _nftid) {
        seller = _seller;
        owner = msg.sender;
        nft = _nft;
        nftid = _nftid;
    }

    function start(uint startingBid) public {
        require(msg.sender == seller, "Only seller can start the auction");
        require(!started, "Auction has already started");

        highestBid = startingBid;

        started = true;
        endAt = block.timestamp + 7 days;

        nft.transferFrom(seller, address(this), nftid);

        emit AuctionStarted();
    }

    function placeBid() external payable {
        require(started, "Auction has not started yet");
        require(!ended, "Auction has already ended");
        require(
            msg.value > highestBid,
            "Bid amount should be higher than highest bid"
        );
        require(block.timestamp < endAt, "Auction has ended");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit BidPlaced(highestBidder, highestBid);
    }

    function withdrawBid() external {
        uint bal = bids[msg.sender];
        require(bal > 0, "No funds to withdraw");

        bids[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: bal}("");

        require(sent, "Could not withdraw funds");

        emit Withdrawn(msg.sender, bal);
    }

    function endAuction() external {
        require(started, "Auction has not started yet");
        require(block.timestamp >= endAt, "Auction has not ended yet");
        require(!ended, "Auction has already ended");

        ended = true;

        if (highestBidder != address(0)) {
            nft.transfer(highestBidder, nftid);

            (bool sent, ) = payable(seller).call{value: highestBid}("");
            require(sent, "Could not transfer funds to seller");
        } else {
            nft.transfer(seller, nftid);
        }

        emit AuctionEnded(highestBidder, highestBid);
    }
}
