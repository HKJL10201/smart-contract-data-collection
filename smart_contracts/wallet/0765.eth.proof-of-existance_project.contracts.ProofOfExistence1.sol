// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ProofOfExistence1 {
    // state
    bytes32 public proof;
    // this function modifies the state, also referred as a transactional function
    function notarize(string memory document) public {
        proof = proofFor(document);
    }
    // this function does not modify the state, it's view only, therefore free
    function proofFor(string memory document) public pure returns (bytes32){
        return sha256(abi.encodePacked(document));
    }
}
