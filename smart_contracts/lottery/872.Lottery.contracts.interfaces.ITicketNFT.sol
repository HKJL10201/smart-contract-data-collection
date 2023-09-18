// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ITicketNFT is IERC1155 {
   function mintNFT(
      address owner_,
      uint256 tokenId_, 
      uint256 amount_
   ) external;
}