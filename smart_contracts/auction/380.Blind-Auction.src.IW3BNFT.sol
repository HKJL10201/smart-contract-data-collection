// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IW3BNFT is IERC721{

    function mint(uint256 _tokenId) external;
}
