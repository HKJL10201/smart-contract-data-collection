pragma solidity ^0.4.2;

contract ProofOfExistence {
    mapping (bytes32 => bool) private proofs;

    // transactional function
    function notarize(string document) {
        bytes32 hashDocument = proofFor(document);
        proofs[hashDocument] = true;
    }

    // read only
    function proofFor(string document) constant returns (bytes32) {
        return sha256(document);
    }

    // read only
    function checkDocument(string document) constant returns (bool) {
        bytes32 hashDocument = proofFor(document);
        return proofs[hashDocument];
    }
}