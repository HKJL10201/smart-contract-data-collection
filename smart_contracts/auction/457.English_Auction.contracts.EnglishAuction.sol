//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from './interfaces/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract EnglishAuction {
    using SafeERC20 for IERC20;

    IERC721 public immutable nft;
    uint256 public immutable nftId;
    address public immutable seller;
    uint32 public endAt;
    bool public started;
    bool public ended;
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public bids;
    IERC20 public immutable auctionToken;

    event Start(uint256 statedAt);
    event Bid(address indexed sender, uint256 amount);
    event Withdraw(address indexed bidder, uint256 amount);
    event End(address highestBidder, uint256 amount);

    constructor(address _nft, uint256 _nftId, uint256 _startingBid, address _seller, address _auctionToken) {
        nft = IERC721(_nft);
        nftId = _nftId;
        highestBid = _startingBid;
        seller = _seller;
        auctionToken = IERC20(_auctionToken);
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Auction: Not a Seller");
        _;
    }

    modifier notStarted() {
        require(!started, "Auction: Has already started");
        _;
    }

    modifier notEnded() {
        require(!ended, "Auction: Has aleready ended");
        _;
    }

    modifier onlyWhenStarted() {
        require(started, "Auction: Is not started yet");
        _;
    }

    function start(uint256 _timeInverval) external onlySeller notStarted {
        started = true;
        endAt = uint32(block.timestamp + _timeInverval);
        nft.transferFrom(seller, address(this), nftId);
        emit Start(block.timestamp);
    }

    function bid(uint256 _bidAmount) external onlyWhenStarted {
        require(msg.sender != seller, "Auction: Seller excluded from bidding");
        require(block.timestamp < endAt, "Auction: Has already ended");
        require(_bidAmount > highestBid, "Auction: Value is less than highest Bid");

        if(highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBid = _bidAmount;
        highestBidder = msg.sender;
        auctionToken.safeTransferFrom(msg.sender, address(this), _bidAmount);
        emit Bid(msg.sender, _bidAmount);
    }

    function withdraw() external {
        uint256 val = bids[msg.sender];
        require(val > 0, "Auction: User does not bid any value / Can not withdraw 0");
        bids[msg.sender] = 0;
        auctionToken.safeTransfer(msg.sender, val);
        emit Withdraw(msg.sender, val);
    }

    function end() external onlyWhenStarted notEnded {
        require(block.timestamp >= endAt, "Auction: Can not be ended yet");
        ended = true;
        if (highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, nftId);
            auctionToken.safeTransfer(seller, highestBid);
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }
        emit End(highestBidder, highestBid);
    }
}