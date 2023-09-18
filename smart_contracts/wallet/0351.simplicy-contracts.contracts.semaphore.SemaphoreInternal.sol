// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IVerifier} from "../interfaces/IVerifier.sol";
import {ISemaphoreInternal} from "./ISemaphoreInternal.sol";
import {SemaphoreStorage} from "./SemaphoreStorage.sol";
import {SemaphoreCoreBaseStorage} from "./base/SemaphoreCoreBase/SemaphoreCoreBaseStorage.sol";
import {SemaphoreCoreBaseInternal} from "./base/SemaphoreCoreBase/SemaphoreCoreBaseInternal.sol";
import {IncrementalBinaryTreeStorage} from "../utils/cryptography/IncrementalBinaryTree/IncrementalBinaryTreeStorage.sol";

/**
 * @title Base SemaphoreGroups internal functions, excluding optional extensions
 */
abstract contract SemaphoreInternal is ISemaphoreInternal, SemaphoreCoreBaseInternal {
    using SemaphoreStorage for SemaphoreStorage.Layout;
    using SemaphoreCoreBaseStorage for SemaphoreCoreBaseStorage.Layout;
    using IncrementalBinaryTreeStorage for IncrementalBinaryTreeStorage.Layout;

    function _verifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) internal virtual {
        
        uint256 root = IncrementalBinaryTreeStorage.layout().trees[groupId].root;
        uint8 depth = IncrementalBinaryTreeStorage.layout().trees[groupId].depth;

        IVerifier verifier = SemaphoreStorage.layout().verifiers[depth];

        _verifyProof(signal, root, nullifierHash, externalNullifier, proof, verifier);

        // Prevent double-voting
        SemaphoreCoreBaseStorage.layout().saveNullifierHash(nullifierHash);
    }

    /**
     * @notice hook that is called before verifyProof
     */
    function _beforeVerifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) internal virtual {
        uint8 depth = IncrementalBinaryTreeStorage.layout().trees[groupId].depth;
        require(depth != 0, "Semaphore: group does not exist");
    }

    /**
     * @notice hook that is called after verifyProof
     */
    function _afterVerifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) internal virtual {}
}
