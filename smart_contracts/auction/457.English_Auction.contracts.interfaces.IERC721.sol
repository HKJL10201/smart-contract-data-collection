//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721 {
    function transferFrom(
        address from, 
        address to,
        uint256 nftId
    ) external;

    function approve(
        address to,
        uint256 tokenId
    ) external;
}