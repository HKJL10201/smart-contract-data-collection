// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./IEA.sol";
import "./IERC721.sol";

contract EnglishAuction is IEA {
    event Start(bool started, uint32 endAt);

    IERC721 private _nft;
    uint256 private _nftId;

    address payable private _owner;
    uint256 private _bidAmount;

    bool private _started;
    bool private _ended;

    uint32 private _endAt;

    address private _highestBidder;
    uint256 private _highestBidAmount;

    mapping(address => uint256) private _bids;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier validAddress() {
        require(msg.sender != address(0), "invalid address");
        _;
    }

    constructor(
        address nft_,
        uint256 nftId_,
        uint256 bidAmount_
    ) {
        require(owner != address(0), "invalid owner");
        require(_bidAmount > 0, "bidAmount < 0");
        _nft = IERC721(nft_);
        _nftId = nftId_;
        _owner = payable(msg.sender);
        _bidAmount = bidAmount_;
    }

    function start() external validAddress onlyOwner {
        require(!_started, "already started");
        _started = true;
        _endAt = (uint32(block.timestamp) + 60);
        _nft.transferFrom(_owner, address(this), _nftId);
        emit Start(_started, _endAt);
    }

    function bid() external payable validAddress {
        require(_started, "not started");
        require(block.timestamp < _endAt, "ended");

        _bids[msg.sender] = _bids[msg.sender] + _highestBidAmount;

        _highestBidder = msg.sender;
        _highestBidAmount = msg.value;
    }

    function withdraw() external {
        require(block.timestamp > _endAt, "current > end");
        require(msg.sender != _highestBidder, "cannot withdraw");
        uint256 bal = _bids[msg.sender];
        _bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);
    }

    function end() external {
        require(_started == true, "not started");
        require(block.timestamp > _endAt, "current < endAt");
        require(_ended == false, "already ended");

        _ended = true;
        if (_highestBidder != address(0)) {
            _nft.transferFrom(address(this), _highestBidder, _nftId);
            _owner.transfer(_highestBidAmount);
        } else {
            _nft.transferFrom(address(this), _owner, _nftId);
        }
    }
}
