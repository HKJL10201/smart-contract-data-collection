// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC721{
    function transferFrom(
        address from, 
        address to, 
        uint256 tokenId)
        external;
}