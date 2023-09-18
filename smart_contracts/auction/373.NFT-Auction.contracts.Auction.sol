// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is Ownable {
    
    IERC721 public nft;

    struct AuctionDetails {
        address payable currentBidder;
        uint256 bidValue;
        uint256 endAt;
        bool started;
    }

    mapping(address => uint) public bidAmounts;    
    mapping(uint256 => AuctionDetails) public bidAsset;    

    constructor (IERC721 nftAddress) {
        nft = nftAddress;
    }

    function startAuction(uint _nftId, uint _startingBid) external onlyOwner {
        require(nft.ownerOf(_nftId) == msg.sender, "Seller not the token Owner");
        require(nft.getApproved(_nftId) == address(this), "Seller not given the approval for contract");
        require(!bidAsset[_nftId].started, "Already started!");

        bidAsset[_nftId] = AuctionDetails(
            payable(address(0)),
            _startingBid,
            block.timestamp + 7 days,
            true
        );

        nft.transferFrom(msg.sender, address(this), _nftId);
    }

    function bid(uint256 _nftId) external payable {
        require(bidAsset[_nftId].started, "Not started.");
        require(bidAsset[_nftId].currentBidder != msg.sender, "This is the current highest bidder");
        require(block.timestamp < bidAsset[_nftId].endAt, "Ended!");
        require(msg.value > bidAsset[_nftId].bidValue, "Bid for a greater amount");

        if (bidAsset[_nftId].currentBidder != address(0)) {
            bidAmounts[bidAsset[_nftId].currentBidder] += bidAsset[_nftId].bidValue;
        }

        bidAsset[_nftId].currentBidder = payable(msg.sender);
        bidAsset[_nftId].bidValue = msg.value;
    }

    function withdraw() external {
        require(bidAmounts[msg.sender] > 0, "No Amount to withdraw");
        uint bal = bidAmounts[msg.sender];
        bidAmounts[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: bal}("");
        require(sent, "Could not withdraw");
    }

     function endAuction(uint256 _nftId) external onlyOwner {
        require(bidAsset[_nftId].started, "You need to start first!");
        require(block.timestamp >= bidAsset[_nftId].endAt, "Auction is still ongoing!");

        if (bidAsset[_nftId].currentBidder != address(0)) {
            nft.transferFrom(address(this), bidAsset[_nftId].currentBidder, _nftId);
            (bool sent, ) = msg.sender.call{value: bidAsset[_nftId].bidValue}("");
            require(sent, "Could not pay seller!");
        }

        else{
            nft.transferFrom(address(this), msg.sender, _nftId);
        }

        delete bidAsset[_nftId];
    }
  
}