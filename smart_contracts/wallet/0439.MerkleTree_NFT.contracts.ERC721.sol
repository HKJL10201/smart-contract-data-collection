// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MyNFT is ERC721 {
    // The Merkle root hash of the whitelist
    bytes32 public whitelistRoot;

    // Mapping of token IDs to whether or not they've been minted
    mapping(uint256 => bool) private _mintedTokens;

    // Mapping of addresses to whether or not they're whitelisted
    mapping(address => bool) private _whitelist;

    // The address of the admin
    address public admin;

    constructor(string memory name, string memory symbol, bytes32 root) ERC721(name, symbol) {
        whitelistRoot = root;
        admin = msg.sender;
    }

    // Function to add an address to the whitelist
    function addToWhitelist(address addr) public {
        require(msg.sender == admin, "Only admin can add to whitelist");
        _whitelist[addr] = true;
    }

    // Function to remove an address from the whitelist
    function removeFromWhitelist(address addr) public {
        require(msg.sender == admin, "Only admin can remove from whitelist");
        _whitelist[addr] = false;
    }

    // Function to check if an address is whitelisted
    function isWhitelisted(address addr) public view returns (bool) {
        return _whitelist[addr];
    }

    // Function to mint a new NFT
    function mint(uint256 tokenId, bytes32[] memory proof) public {
        require(_whitelist[msg.sender], "Sender is not whitelisted");
        require(!_mintedTokens[tokenId], "Token already minted");
        require(MerkleProof.verify(proof, whitelistRoot, bytes32(uint256(uint160(msg.sender)))), "Invalid proof");
        // Mint the token and mark it as minted
        _mint(msg.sender, tokenId);
        _mintedTokens[tokenId] = true;
    }
}
