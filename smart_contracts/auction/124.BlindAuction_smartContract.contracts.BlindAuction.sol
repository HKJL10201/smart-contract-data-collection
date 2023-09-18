// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTBlindAuction {


struct Bid {
    bytes32 blindedBid;
    uint deposit;
    address bidder;
}

address payable public owner;
uint public biddingEnd;
uint public revealEnd;
bool public ended;

mapping(address => Bid[]) public bids;

address public highestBidder;
uint public highestBid;

mapping(address => uint) pendingReturns;

IERC721 public nftContract;
uint256 public tokenId;
uint256 public initialPrice;

error TooEarly(uint time);
error TooLate(uint time);
error AuctionEndAlreadyCalled();
error notOwner();

event AuctionEnded(address highestBidder, uint highestBid);

constructor(uint _biddingTime, uint _revealTime, address payable _ownerAddress, address _nftContractAddress, uint256 _tokenId, uint256 _initialPrice) {
    owner = _ownerAddress;
    biddingEnd = block.timestamp + _biddingTime;
    revealEnd = biddingEnd + _revealTime;
    nftContract = IERC721(_nftContractAddress);
    tokenId = _tokenId;
    nftContract.transferFrom(msg.sender, address(this), _tokenId);
    initialPrice = _initialPrice;
}

modifier onlyBefore(uint _time) {
    if(block.timestamp >= _time) revert TooLate(_time - block.timestamp);
    _;
}

modifier onlyAfter(uint _time) {
    if(block.timestamp <= _time) revert TooEarly(_time - block.timestamp);
    _;
}


function blind_my_bid(uint _value, bool _fake, bytes32 _secret) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_value, _fake, _secret));
}

function bid(bytes32 _blindedBid) external payable onlyBefore(biddingEnd) {
    require(msg.value > 0, "Deposit must be greater than 0");
    bids[msg.sender].push(Bid({
        blindedBid: _blindedBid,
        deposit: msg.value,
        bidder: msg.sender
    }));
}

function reveal(uint[] calldata _values, bool[] calldata _fakes, bytes32[] calldata _secrets) external onlyAfter(biddingEnd) onlyBefore(revealEnd) {
    uint length = bids[msg.sender].length;
    require(_values.length == length);
    require(_fakes.length == length);
    require(_secrets.length == length);

    uint refund;

    for (uint i = 0; i < length; i++) {
        Bid storage bidToCheck = bids[msg.sender][i];
        (uint _value, bool _fake, bytes32 _secret) = (_values[i], _fakes[i], _secrets[i]);
        if (bidToCheck.blindedBid != keccak256(abi.encodePacked(_value, _fake, _secret))) {
            continue;
        }

        refund += bidToCheck.deposit;

        if (!_fake && bidToCheck.deposit >= _value) {
            if (placeBid(bidToCheck.bidder, _value))
                refund -= _value;
        }

        bidToCheck.blindedBid = bytes32(0);
    }

    payable(msg.sender).transfer(refund);
}

    function withdraw() external {
        require(ended, "Auction has not ended yet");
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    function auctionEnd() external onlyAfter(revealEnd) {
        if (ended) revert AuctionEndAlreadyCalled();
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        owner.transfer(highestBid);
    }

    function placeBid(address _bidder, uint _value) internal returns(bool success) {
        if (_value < initialPrice) {
            return false;
        }
        
        if (_value <= highestBid) {
            return false;
        }

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = _value;
        highestBidder = _bidder;
        return true;
    }

    function claimNFT() external {
        require(ended, "Auction has not ended yet");
        require(msg.sender == highestBidder, "Only the highest bidder can claim this nft");

        IERC721(nftContract).safeTransferFrom(address(this), msg.sender, tokenId);

        emit AuctionEnded(highestBidder, highestBid);
    }

    function getBidderCount(address bidder) external view returns (uint256) {
        return bids[bidder].length;
    }

    function getBidderAddress(uint256 index) external view returns (address) {
        require(index < bids[msg.sender].length, "Invalid index");
        return bids[msg.sender][index].bidder;
    }

}