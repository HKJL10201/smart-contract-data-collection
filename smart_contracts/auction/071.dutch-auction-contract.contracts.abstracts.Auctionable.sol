//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Auctionable
 */

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import "./Controlable.sol";
import "../libs/DutchAuctionModel.sol";

contract Auctionable is Controlable {
    mapping(bytes32 => DutchAuctionModel.Auctions) auctions;

    function __Auctionable_init() internal onlyInitializing {
        __Auctionable_init_unchained();
    }

    function __Auctionable_init_unchained() internal onlyInitializing {
    }

    function _createAuction(
        DutchAuctionModel.TOKEN_TYPE type_,
        address nftContract_,
        uint256 tokenId_,
        uint256 startDate_,
        uint256 startPrice_,
        uint256 endDate_,
        uint256 endPrice_
    ) internal returns (bool success) {
        require(startDate_ >= block.timestamp, "DutchAuction: Start date must be in the future");
        require(endDate_ > startDate_, "DutchAuction: End date must be after start date");
        require(endPrice_ < startPrice_, "DutchAuction: End price must be smaller than start price or 0");
        require(validNfts[nftContract_], "DutchAuction: Token contract is not valid");
        IERC721Upgradeable(nftContract_).transferFrom(msg.sender, address(this), tokenId_);

        bytes32 auctionId = _getAuctionId(msg.sender, nftContract_, tokenId_, startDate_, startPrice_, endDate_);
        require(auctions[auctionId].status == DutchAuctionModel.AUCTION_STATUS.NOT_ASSIGNED, "Auction already exists");

        auctions[auctionId] = DutchAuctionModel.Auctions(
            DutchAuctionModel.AUCTION_STATUS.STARTED,
            type_,
            msg.sender,
            nftContract_,
            tokenId_,
            startDate_,
            startPrice_,
            endDate_,
            endPrice_
        );
        emit DutchAuctionModel.AuctionCreated(auctionId, msg.sender, nftContract_, tokenId_, startDate_, startPrice_, endDate_, endPrice_);
        return true;
    }

    function _bid(bytes32 auctionId_) internal returns (bool success) {
        DutchAuctionModel.Auctions memory auction = auctions[auctionId_];
        uint256 bidPrice = _getAuctionPrice(auctionId_);
        require(bidPrice > 0, "DutchAuction: Auction id not valid or already finished");

        require(token.transferFrom(msg.sender, auction.tokenOwner, bidPrice), "DutchAuction: Failed to transfer token");

        auctions[auctionId_].status = DutchAuctionModel.AUCTION_STATUS.SOLD;
        emit DutchAuctionModel.AuctionClosed(auctionId_, msg.sender, bidPrice);

        IERC721Upgradeable(auction.tokenContract).transferFrom(address(this), msg.sender, auction.tokenId);
        return true;
    }

    function _reclaim(bytes32 auctionId_) internal returns (bool success) {
        require(auctions[auctionId_].status == DutchAuctionModel.AUCTION_STATUS.STARTED, "DutchAuction: Auction id not valid or already finished");
        require(auctions[auctionId_].endDate < block.timestamp, "DutchAuction: Auction is not finished");
        require(auctions[auctionId_].tokenOwner == msg.sender, "DutchAuction: Only the auction owner can reclaim the token");
        auctions[auctionId_].status = DutchAuctionModel.AUCTION_STATUS.CLOSED;

        emit DutchAuctionModel.AuctionClosed(auctionId_, auctions[auctionId_].tokenOwner, 0);

        IERC721Upgradeable(auctions[auctionId_].tokenContract).transferFrom(address(this), auctions[auctionId_].tokenOwner, auctions[auctionId_].tokenId);
        return true;
    }

    function _getAuction(bytes32 auctionId_) internal view returns (DutchAuctionModel.Auctions memory) {
        return auctions[auctionId_];
    }

    function _verifyNftIsValid(address tokenContract_) internal view returns (bool isValid) {
        return validNfts[tokenContract_];
    }

    function _getAuctionPrice(bytes32 auctionId_) internal view returns (uint256) {
        DutchAuctionModel.Auctions memory auction = auctions[auctionId_];
        require(auction.status == DutchAuctionModel.AUCTION_STATUS.STARTED, "DutchAuction: Auction id not valid or already finished");
        require(auction.endDate >= block.timestamp, "DutchAuction: Auction has already finished");

        if(block.timestamp <= auction.startDate)
            return auction.startPrice;

        return ((auction.startPrice - auction.endPrice) / 
                (auction.endDate - auction.startDate) * 
                (auction.endDate - block.timestamp) +
                auction.endPrice);
    }


    function _getAuctionId(
        address owner_,
        address tokenContract_,
        uint256 tokenId_,
        uint256 startDate_,
        uint256 startPrice_,
        uint256 endDate_
    ) public pure returns (bytes32) {
        return keccak256(
                abi.encodePacked(
                    owner_,
                    tokenContract_,
                    tokenId_,
                    startDate_,
                    startPrice_,
                    endDate_
                )
            );
    }
}
