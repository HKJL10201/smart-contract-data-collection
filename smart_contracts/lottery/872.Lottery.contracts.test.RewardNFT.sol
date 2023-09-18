// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RewardNFT is ERC721 {
   using Counters for Counters.Counter;
   Counters.Counter private tokenId;

   constructor(
      string memory name_,
      string memory symbol_
   ) ERC721(name_, symbol_) {}

   function mintNFT(address owner_) external {
      _safeMint(owner_, tokenId.current());
      tokenId.increment();
   }
}