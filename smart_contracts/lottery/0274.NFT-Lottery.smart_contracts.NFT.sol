pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Mintable.sol";

contract NFT is ERC721Full, ERC721Mintable {
  constructor(string memory name, string memory symbol) ERC721Full(name, symbol) public {}
}