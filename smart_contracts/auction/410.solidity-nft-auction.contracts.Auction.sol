// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Auction is IERC721Receiver {
    address public seller; // auction item owner

    // nft and nftId seller want to sell
    IERC721 public nft;
    uint public nftId;

    bool public finished; // if finished before endAt
    bool public cancelled; // cancelled by seller
    uint public endAt; // after this ts auction is finished automaically
    uint public startPrice;
    uint public buyNowPrice;
    uint public minBidIncrement;
    uint public highestBid;
    address public highestBidder;
    mapping(address => uint256) bids;

    event Started(); // endAt is set and auction started
    event Finished(); // somebody won the item
    event Cancelled(); // cancelled by seller
    event NewBid(uint indexed bid, address indexed bidder);
    event Withdrawn(uint amount, address to);

    constructor(
        address _seller,
        uint _startPrice,
        uint _buyNowPrice,
        uint _minBidIncrement
    ) {
        seller = payable(_seller);
        buyNowPrice = _buyNowPrice;
        minBidIncrement = _minBidIncrement;
        startPrice = _startPrice;

        require(
            buyNowPrice > minBidIncrement,
            "Bid increment is higher than buy now price"
        );
        require(
            (startPrice * 100) / buyNowPrice < 70,
            "Buy now price must be at least 30% higher than start price"
        );
    }

    function start(IERC721 _nft, uint _nftId) public onlySeller notStarted {
        nft = _nft;
        nftId = _nftId;
        // transfer nft from seller to contract address
        nft.safeTransferFrom(msg.sender, address(this), nftId);

        // to simplify, default auction period is one week
        endAt = block.timestamp + 7 days; 
        emit Started();
    }

    function isStarted() external view returns (bool) {
        return _isStarted();
    }

    function isFinished() external view returns (bool) {
        return _isFinished();
    }

    function bid() public payable notSeller notCancelled notFinished onlyStarted {
        require(msg.value >= minBidIncrement, "Not enough bid amount");

        uint newBidAmount = bids[msg.sender] + msg.value;
        bids[msg.sender] = newBidAmount;

        if (newBidAmount > highestBid) {
            highestBid = newBidAmount;
            highestBidder = msg.sender;
        }

        emit NewBid(msg.value, msg.sender);

        if (newBidAmount >= buyNowPrice) {
            // we have a winner!
            _finish();
        }
    }

    function getMyBid() external view returns (uint) {
        // anyone can see his current bid
        return bids[msg.sender];
    }

    function getTheWinner() public view onlyFinished returns (address) {
        return highestBidder;
    }

    function withdraw() external payable finishedOrCancelled {
        address to;
        uint amount;

        if (cancelled) {
            // everyone can return his funds, seller got nothing
            to = msg.sender;
            amount = bids[msg.sender];
            delete bids[msg.sender];
        } else {
            // auction finished or ended
            if (msg.sender == seller) {
                // seller can withdraw the price payment
                to = seller;
                // but not higher than buy now price
                amount = min(highestBid, buyNowPrice);
                bids[highestBidder] -= amount;
            } else if (msg.sender == highestBidder) {
                // highest bidden can withdraw difference between highest bid and buy now
                to = highestBidder;
                amount = highestBid - buyNowPrice;
                bids[to] -= amount;
            } else {
                // anyone else can withdraw his funds
                to = msg.sender;
                amount = bids[msg.sender];
                bids[to] -= amount;
            }
        }

        require(amount > 0, "Nothing to withdraw");

        to = payable(to);
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to send payment");

        emit Withdrawn(amount, to);
    }

    function getReward() external payable onlyFinished {
        require(highestBidder != address(0));
        // send nft to winner
        nft.safeTransferFrom(address(this), highestBidder, nftId);
    }

    /**
     * seller may cancell auction
     */
    function cancell()
        public
        onlySeller
        beforeEndDate
        notFinished
        notCancelled
    {
        // send NFT back to seller
        nft.safeTransferFrom(address(this), seller, nftId);
        cancelled = true;
        emit Cancelled();
    }

    // to safely accept NFC using IERC721.safeTransferFrom function
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function _finish() internal notFinished onlyStarted {
        // auction finished before endAt datetime
        finished = true;
        emit Finished();
    }

    function _isFinished() internal view returns (bool) {
        // buy now is exceeded or time is ended
        return finished || (endAt > 0 && endAt <= block.timestamp);
    }

    function _isStarted() internal view returns (bool) {
        return endAt > 0;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Not a seller");
        _;
    }

    modifier notSeller() {
        require(msg.sender != seller, "Seller can't do it");
        _;
    }

    modifier beforeEndDate() {
        require(block.timestamp < endAt, "Auction ended");
        _;
    }

    modifier onlyFinished() {
        require(_isFinished(), "Auction not finished");
        _;
    }

    modifier notFinished() {
        require(!_isFinished(), "Auction already finished");
        _;
    }

    modifier finishedOrCancelled() {
        require(cancelled || _isFinished(), "Auction is ongoing!");
        _;
    }

    modifier notStarted() {
        require(!_isStarted(), "Auction already started");
        _;
    }

    modifier onlyStarted() {
        require(_isStarted(), "Auction not started yet");
        _;
    }

    modifier notCancelled() {
        require(!cancelled, "Auction cancelled by seller");
        _;
    }
}
