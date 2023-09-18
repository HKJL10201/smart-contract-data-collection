// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./NFT-standard/ERC721.sol";
import "./NFT-standard/ERC721URIStorage.sol";

// Contract representing TRYlottery's NFT token
contract TRYNFT is ERC721URIStorage{
    uint256 private _tokenIds;
    address private _owner;

    // The token will always have the same name and symbol
    constructor() ERC721("TRYNFT", "TRY") {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Caller is not the owner");
        _;
    }

    /* Calls ERC721's '_mint' function creating a new token with a unique id and
    ERC721URIStorage's '_setTokenURI' function setting the location for tokent's metadata */
    function mintNFT(address recipient, string memory tokenURI) public onlyOwner returns (uint256) {
        _tokenIds++;
        _mint(recipient, _tokenIds);
        _setTokenURI(_tokenIds, tokenURI);

        return _tokenIds;
    }

    // Transfers the ownership of this contract to a new address
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        _owner = newOwner;
    }
}