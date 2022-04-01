// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTArt is ERC721URIStorage, Ownable {

    uint256 private tokenId;

	event Mint_TokenID(uint256 _tokenId);

    constructor() ERC721("Paint","PNT") {}

    function mint(address to, string memory tokenURI) public onlyOwner returns (uint256) {
        tokenId++;
        _mint(to, tokenId);
		emit Mint_TokenID(tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }

    function existsTID(uint256 tokId) public view returns (bool) {
        return _exists(tokId);
    }

}