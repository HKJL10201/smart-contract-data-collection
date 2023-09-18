// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./interface/ISwap.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Swap is ISwap {
    using Counters for Counters.Counter;

    address private _operator = address(this);

    mapping(uint256 => Trade) public idToTrade;

    Counters.Counter private _tradeIds;

    function initiateTrade(
        address[] calldata collectionsToSend,
        uint256[] calldata nftIndicesToSend,
        address[] calldata collectionsToReceive,
        uint256[] calldata nftIndicesToReceive
    ) external override {
        require(collectionsToSend.length > 0 && collectionsToReceive.length > 0, "Arrays empty");

        validateOperatorApproval(msg.sender, _operator, collectionsToSend);

        // make sure owner for nfts is the sender
        validateCollectionOwner(msg.sender, collectionsToSend, nftIndicesToSend);

        // make sure owner is the same for all nfts
        address nftOwner = IERC721(collectionsToReceive[0]).ownerOf(nftIndicesToReceive[0]);
        validateCollectionOwner(nftOwner, collectionsToReceive, nftIndicesToReceive);

        // create trade
        _tradeIds.increment();
        uint256 tradeId = _tradeIds.current();
        idToTrade[tradeId] = Trade(
            tradeId,
            msg.sender,
            nftOwner,
            collectionsToSend,
            nftIndicesToSend,
            collectionsToReceive,
            nftIndicesToReceive
        );
    }

    function acceptTrade(uint256 tradeId) external override {
        // get trade
        Trade memory trade = idToTrade[tradeId];
        require(trade.senderId != address(0) && trade.receiverId != address(0), "Trade does not exist");
        require(trade.receiverId == msg.sender, "Not receiver");

        // validate that trade sender and receiver still own the NFTs
        validateCollectionOwner(trade.senderId, trade.collectionsToSend, trade.nftIndicesToSend);
        validateCollectionOwner(msg.sender, trade.collectionsToReceive, trade.nftIndicesToReceive);

        validateOperatorApproval(trade.senderId, _operator, trade.collectionsToSend);

        // swap NFTs
        for (uint256 i = 0; i < trade.collectionsToSend.length; i++) {
            IERC721(trade.collectionsToSend[i]).safeTransferFrom(trade.senderId, msg.sender, trade.nftIndicesToSend[i]);
        }

        for (uint256 i = 0; i < trade.collectionsToReceive.length; i++) {
            IERC721(trade.collectionsToReceive[i]).safeTransferFrom(msg.sender, trade.senderId, trade.nftIndicesToReceive[i]);
        }

        // remove trade
        delete idToTrade[tradeId];
    }

    function validateCollectionOwner(address owner, address[] memory collections, uint256[] memory nftIndices) private view {
        require(collections.length == nftIndices.length, "Array length mismatch");

        for (uint256 i = 0; i < collections.length; i++) {
            address nftOwner = IERC721(collections[i]).ownerOf(nftIndices[i]);
            require(nftOwner != address(0) && nftOwner == owner, "NFT unowned");
        }
    }

    function validateOperatorApproval(address owner, address operator, address[] memory collections) private view {
        for (uint256 i = 0; i < collections.length; i++) {
            require(IERC721(collections[i]).isApprovedForAll(owner, operator), "Not approved for all");
        }
    }
}