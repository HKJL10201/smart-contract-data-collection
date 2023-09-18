//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract Merkle {

     //The root hash of the Merkle Tree we previously generated in the index.js. 
     bytes32 public merkleRoot = 0x06234fd81f536fd9b094b50bf3e71db9dd3078acfd0565e9a57625a5700b9829;

     //mapping variable to mark whitelist addresses as having claimed
     mapping(address => bool) public whitelistClaimed;

     function whitelistMint(bytes32[] calldata _merkleProof) public {
          
          //this will help validation to ensure the NFT wallet hasn't already been claimed
          require(!whitelistClaimed[msg.sender], "NFT Address has already claimed.");

          bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
          require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "You Have Invalid proof.");

          //mark NFT address as having claimed their token
          whitelistClaimed[msg.sender] = true;
     }
}