// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract GenerateCommit {
    function hash(uint256 value, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(value, nonce));
    }
}
