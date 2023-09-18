// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../node_modules/@openzeppelin/contracts/utils/Counters.sol";

contract Solirey is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    Counters.Counter public _uid;
    address payable public admin; 
    // The original artist: token ID to the artist address
    mapping (uint256 => address) public _artist;
    // uint public uid;

    constructor() ERC721("Solirey", "SREY") {
        admin = payable(msg.sender);
    }

    function incrementToken() public {
        _tokenIds.increment();
    }

    function currentToken() public view returns (uint256) {
        return _tokenIds.current();
    }

    function incrementUid() public {
        _uid.increment();
    }

    function currentUid() public view returns (uint256) {
        return _uid.current();
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    // ERC720 token transfer
    // function tokenTransfer(address from, address to, uint256 tokenId) public {
    //     // require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    //     // require(tx.origin == ownerOf(tokenId) || isApprovedForAll(ownerOf(tokenId), msg.sender), "Not authorized");
    //     require(tx.origin == ownerOf(tokenId));
    //     _transfer(from, to, tokenId);
    // }

    // function abortTransfer(address from, address to, uint256 tokenId) public {
    //     require(isApprovedForAll(ownerOf(tokenId), msg.sender), "Not authorized");
    //     _transfer(from, to, tokenId);
    // }

    function updateArtist(uint256 id, address artist) public returns (bool success) {
        _artist[id] = artist;
        return true;
    }
}