// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ProofOfExistence2 {
    // state
    bytes32[] private proofs;
    // bytes32[] means you are creating an arr of dynamic length of bytes32 types
    function storeProof(bytes32 proof)
        public 
        {
            proofs.push(proof);
        }
    function notarize(string calldata document) external {
        bytes32 proof = proofFor(document);
        storeProof(proof);
    }
    function proofFor(string memory document) 
        pure 
        public
        returns (bytes32)
        {
            return sha256(abi.encodePacked(document));
        }
    function checkDocument(string memory document)
        public
        view
        returns (bool)
        {
            bytes32 proof = proofFor(document);
            return hasProof(proof);
        }
    function hasProof(bytes32 proof)
        internal
        view
        returns (bool)
        {
            for (uint256 i =0; i < proofs.length; i++){
                if (proofs[i] == proof) {
                    return true;
                }
            }
            return false;
        }

}
