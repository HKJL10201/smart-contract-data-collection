//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library Helper {
  function generateRandomNumber(address owner) public view returns (uint){
    return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
  }
}