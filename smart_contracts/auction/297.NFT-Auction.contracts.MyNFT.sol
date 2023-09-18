// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

// We need some util functions for strings.
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";



contract MyNFT is ERC721URIStorage {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  uint public totalMintCount;
  

  constructor(uint TOTAL_MINT_COUNT) ERC721 ("myNFT2", "NFT2") {
    totalMintCount = TOTAL_MINT_COUNT;
    console.log("This is my NFT contract. Woah!");
  }


  function makeAnNFT() public {
    uint256 newItemId = _tokenIds.current();

    require(newItemId <= totalMintCount, "All the tokens have been minted.");
    

    _safeMint(msg.sender, newItemId);
  
    // We'll be setting the tokenURI later!
    _setTokenURI(newItemId, "ipfs://QmZnKAjhr7MJgE5BemCg15jmZEZSk5Pd2zK17GbGciHS2y");
  
    _tokenIds.increment();
    console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);

  }
}