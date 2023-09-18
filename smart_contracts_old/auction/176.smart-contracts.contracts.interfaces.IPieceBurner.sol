// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;


/**
 * @title IPieceBurner
 */
interface IPieceBurner {
    function swap(uint256 tokenId, address receiver) external;
    function batchSwap(uint256[] memory tokenIds, address receiver) external;
}