// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IVerifier} from "../../../interfaces/IVerifier.sol";
import {ISemaphoreCoreBaseInternal} from "./ISemaphoreCoreBaseInternal.sol";
import {SemaphoreCoreBaseStorage} from "./SemaphoreCoreBaseStorage.sol";

/**
 * @title Base SemaphoreGroups internal functions, excluding optional extensions
 */
abstract contract SemaphoreCoreBaseInternal is ISemaphoreCoreBaseInternal {
    using SemaphoreCoreBaseStorage for SemaphoreCoreBaseStorage.Layout;    

     /**
     * @notice asserts that no nullifier already exists and if the zero-knowledge proof is valid
     * @param signal: Semaphore signal.
     * @param root: Root of the Merkle tree.
     * @param nullifierHash: Nullifier hash.
     * @param externalNullifier: External nullifier.
     * @param proof: Zero-knowledge proof.
     * @param verifier: Verifier address.
     */
    function _verifyProof(
        bytes32 signal,
        uint256 root,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        IVerifier verifier
    ) internal view {
        require(!SemaphoreCoreBaseStorage.layout().nullifierHashes[nullifierHash], "SemaphoreCore: you cannot use the same nullifier twice");

        uint256 signalHash = _hashSignal(signal);

        verifier.verifyProof(
            [proof[0], proof[1]],
            [[proof[2], proof[3]], [proof[4], proof[5]]],
            [proof[6], proof[7]],
            [root, nullifierHash, signalHash, externalNullifier]
        );
    }

    /**
     * @notice creates a keccak256 hash of the signal
     * @param signal: Semaphore signal
     * @return Hash of the signal
     */
    function _hashSignal(bytes32 signal) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(signal))) >> 8;
    }
}
