// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IRewardNFT is IERC721 {
    function mintNFT(address owner_) external;
}