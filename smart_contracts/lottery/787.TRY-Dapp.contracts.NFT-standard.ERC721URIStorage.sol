// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./ERC721.sol";

abstract contract ERC721URIStorage is ERC721 {
    mapping (uint256 => string) private _tokenURIs;

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId]; // TODO: ??
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol
        return _tokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "URI set for nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
}