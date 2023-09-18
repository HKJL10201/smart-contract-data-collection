// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC721 {
    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

contract Auction is ReentrancyGuard {
    event Start();
    event End(address highestBidder, uint256 highestBid);
    event Bid(address indexed sender, uint256 amount);
    event Withdraw(address indexed bidder, uint256 amount);

    address payable public immutable seller;

    bool public started;
    bool public ended;

    uint256 public startAt;
    uint256 public duration;
    uint256 public endAt;
    uint256 public increment;

    IERC721 public nft; // address of the NFT
    uint256 public nftId;

    uint256 public highestBid;
    address public highestBidder;
    mapping(address => uint256) public bids;

    constructor(
        address sender,
        IERC721 _nft,
        uint256 _nftId,
        uint256 _startingBid,
        uint256 _increment,
        uint256 _duration
    ) {
        require(_startingBid > 0, "Starting bid must be greater than 0!");
        require(_increment > 0, "Increment must be greater than 0!");
        require(_duration > 0, "Duration must be greater than 0!");
        seller = payable(sender);
        highestBid = _startingBid;
        increment = _increment;
        duration = _duration;

        nft = _nft;
        nftId = _nftId;
        duration = _duration;
    }

    function start() external {
        require(!started, "Auction already started!");
        require(msg.sender == seller, "You are not the owner of this auction!");

        nft.transferFrom(msg.sender, address(this), nftId);
        started = true;
        startAt = block.timestamp;
        endAt = startAt + duration;

        emit Start();
    }

    function getPrice() public view returns (uint256) {
        return highestBid;
    }

    function info()
        public
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            bool,
            address
        )
    {
        return (
            seller,
            highestBidder,
            startAt,
            duration,
            endAt,
            increment,
            highestBid,
            nftId,
            bids[msg.sender],
            started,
            ended,
            address(nft)
        );
    }

    function bid() external payable {
        require(started, "Auction not started!");
        require(!ended, "Auction ended!");
        require(block.timestamp < endAt, "Auction ended!");
        require(msg.sender != seller, "You are the seller!");
        if (highestBidder != address(0)) {
            // only check if this is NOT the first offer
            // as the msg.value in first offer represents the starting bid
            require(
                msg.value >= increment,
                "Insufficient bid amount increment!"
            );
        }
        require(
            msg.value + bids[msg.sender] > highestBid,
            "Bid must be greater than highest bid!"
        );

        highestBid = msg.value + bids[msg.sender];
        bids[msg.sender] = highestBid;
        highestBidder = msg.sender;

        emit Bid(highestBidder, highestBid);
    }

    function withdraw() external payable nonReentrant {
        require(started, "Auction not started!");
        require(msg.sender != highestBidder, "Highest bidder cannot withdraw.");
        uint256 bal = bids[msg.sender];
        require(bal > 0, "No balance to withdraw.");

        bids[msg.sender] = 0; // Ensure all state changes happen before calling external contracts
        (bool sent, ) = payable(msg.sender).call{value: bal}("");
        require(sent, "Could not withdraw");

        emit Withdraw(msg.sender, bal);
    }

    function end() external nonReentrant {
        require(started, "You need to start first!");
        require(block.timestamp >= endAt, "Auction is still ongoing!");
        require(!ended, "Auction already ended!");
        ended = true; // Ensure all state changes happen before calling external contracts

        if (highestBidder != address(0)) {
            // Someone bidded
            nft.transferFrom(address(this), highestBidder, nftId);
            (bool sent, ) = seller.call{value: highestBid}("");
            require(sent, "Could not pay seller!");
        } else {
            // no one bidded
            nft.transferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}
