// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ISwap {
    struct Trade {
        uint256 tradeId;
        address senderId;
        address receiverId;
        address[] collectionsToSend;
        uint256[] nftIndicesToSend;
        address[] collectionsToReceive;
        uint256[] nftIndicesToReceive;
    }

    function initiateTrade(
        address[] memory collectionsToSend,
        uint256[] memory nftIndicesToSend,
        address[] memory collectionsToReceive,
        uint256[] memory nftIndicesToReceive
    ) external;

    function acceptTrade(uint256 tradeId) external;
}