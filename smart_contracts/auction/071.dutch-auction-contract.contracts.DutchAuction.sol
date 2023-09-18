//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title DutchAuction
 */

import "./abstracts/Auctionable.sol";
import "./libs/DutchAuctionModel.sol";


contract DutchAuction is Auctionable {
    function initialize(
        IERC20Upgradeable tokenContract_
    ) external initializer {
        __Controlable_init(tokenContract_);
        __Auctionable_init();
    }

    function createAuction(
        DutchAuctionModel.TOKEN_TYPE type_,
        address nftContract_,
        uint256 tokenId_,
        uint256 startDate_,
        uint256 startPrice_,
        uint256 endDate_,
        uint256 endPrice_
    ) external returns (bool success) {
        return _createAuction(type_, nftContract_, tokenId_, startDate_, startPrice_, endDate_, endPrice_);
    }

    function bid(bytes32 auctionId_) external returns (bool success) {
        return _bid(auctionId_);
    }

    function reclaim(bytes32 auctionId_) external returns (bool success) {
        return _reclaim(auctionId_);
    }

    function getAuctionId(
        address owner_,
        address tokenContract_,
        uint256 tokenId_,
        uint256 startDate_,
        uint256 startPrice_,
        uint256 endDate_
    ) public pure returns (bytes32) {
        return _getAuctionId(owner_, tokenContract_, tokenId_, startDate_, startPrice_, endDate_);
    }

    function getAuction(bytes32 auctionId_) public view returns (DutchAuctionModel.Auctions memory) {
        return _getAuction(auctionId_);
    }

    function verifyNftIsValid(address tokenContract_) public view returns (bool isValid) {
        return _verifyNftIsValid(tokenContract_);
    }

    function getAuctionPrice(bytes32 auctionId_) public view returns (uint256) {
        return _getAuctionPrice(auctionId_);
    }
}
