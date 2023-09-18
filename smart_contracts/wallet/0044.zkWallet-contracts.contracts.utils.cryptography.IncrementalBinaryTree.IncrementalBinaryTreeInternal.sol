// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {SNARK_SCALAR_FIELD, MAX_DEPTH} from "../../Constants.sol";
import {PoseidonT3} from "../Hashes.sol";
import {IIncrementalBinaryTreeInternal} from "./IIncrementalBinaryTreeInternal.sol";
import {IncrementalBinaryTreeStorage} from "./IncrementalBinaryTreeStorage.sol";

/**
 * @title Base IncrementalBinaryTree internal functions, excluding optional extensions
 */
abstract contract IncrementalBinaryTreeInternal is IIncrementalBinaryTreeInternal {
    using IncrementalBinaryTreeStorage for IncrementalBinaryTreeStorage.Layout;
    using IncrementalBinaryTreeStorage for IncrementalBinaryTreeStorage.IncrementalTreeData;

    /**
     * @notice See {ISemaphoreGroups-getRoot}
     */
    function _getRoot(uint256 treeId) internal view virtual returns (uint256) {
        return IncrementalBinaryTreeStorage.layout().trees[treeId].root;
    }

    /**
     * @notice See {ISemaphoreGroups-getDepth}
     */
    function _getDepth(uint256 treeId) internal view virtual returns (uint8) {
        return IncrementalBinaryTreeStorage.layout().trees[treeId].depth;
    }

    function _getZeroes(uint256 treeId, uint256 leafIndex)
        internal
        view
        returns (uint256)
    {
        return
            IncrementalBinaryTreeStorage.layout().trees[treeId].zeroes[
                leafIndex
            ];
    }

    /**
     * @notice See {ISemaphoreGroups-getNumberOfLeaves}
     */
    function _getNumberOfLeaves(uint256 treeId)
        internal
        view
        virtual
        returns (uint256)
    {
        return
            IncrementalBinaryTreeStorage.layout().trees[treeId].numberOfLeaves;
    }

    /**
     * @notice query trees of a group
     */
    function getTreeData(uint256 treeId)
        internal
        view
        virtual
        returns (IncrementalBinaryTreeStorage.IncrementalTreeData storage treeData)
    {
        return IncrementalBinaryTreeStorage.layout().trees[treeId];
    }

    /**
     * @notice initializes a tree
     * @param treeId:  group id of the group
     * @param depth: depth of the tree
     * @param zero: zero value to be used
     */
    function _init(
        uint256 treeId,
        uint8 depth,
        uint256 zero
    ) internal virtual {
        require(zero < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(depth > 0 && depth <= MAX_DEPTH, "IncrementalBinaryTree: tree depth must be between 1 and 32");

        IncrementalBinaryTreeStorage.layout().setDepth(treeId, depth);

        for (uint8 i = 0; i < depth; i++) {
            IncrementalBinaryTreeStorage.layout().setZeroes(treeId, i, zero);
            zero = PoseidonT3.poseidon([zero, zero]);
        }

        IncrementalBinaryTreeStorage.layout().setRoot(treeId, zero);
    }

    /**
     * @notice inserts a leaf in the tree
     * @param treeId:  group id of the group
     * @param leaf: Leaf to be inserted
     */
    function _insert(uint256 treeId, uint256 leaf) internal virtual {       
        uint256 index = _getNumberOfLeaves(treeId);
        uint256 hash = leaf;
        IncrementalBinaryTreeStorage.IncrementalTreeData
            storage data = IncrementalBinaryTreeStorage.layout().trees[treeId];

        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(index < 2**_getDepth(treeId), "IncrementalBinaryTree: tree is full");

        for (uint8 i = 0; i < _getDepth(treeId); i++) {
            if (index % 2 == 0) {
                data.lastSubtrees[i] = [hash, _getZeroes(treeId, i)];
            } else {
                data.lastSubtrees[i][1] = hash;
            }

            hash = PoseidonT3.poseidon(data.lastSubtrees[i]);
            index /= 2;
        }

        IncrementalBinaryTreeStorage.layout().setRoot(treeId, hash);
        IncrementalBinaryTreeStorage.layout().setNumberOfLeaves(treeId);
    }

    /**
     * @notice removes a leaf from the tree
     * @param treeId:  group id of the group
     * @param leaf: leaf to be removed
     * @param proofSiblings: array of the sibling nodes of the proof of membership
     * @param proofPathIndices: path of the proof of membership
     */
    function _remove(
        uint256 treeId,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) internal virtual {
        require(_verify(treeId, leaf, proofSiblings, proofPathIndices), "IncrementalBinaryTree: leaf is not part of the tree");
        
        IncrementalBinaryTreeStorage.IncrementalTreeData
            storage data = IncrementalBinaryTreeStorage.layout().trees[treeId];

        uint256 hash = _getZeroes(treeId, 0);

        for (uint8 i = 0; i < _getDepth(treeId); i++) {
            if (proofPathIndices[i] == 0) {
                if (proofSiblings[i] == data.lastSubtrees[i][1]) {
                    data.lastSubtrees[i][0] = hash;
                }

                hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
            } else {
                if (proofSiblings[i] == data.lastSubtrees[i][0]) {
                    data.lastSubtrees[i][1] = hash;
                }

                hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
            }
        }

        IncrementalBinaryTreeStorage.layout().setRoot(treeId, hash);
    }

    /**
     * @notice verify if the path is correct and the leaf is part of the tree
     * @param leaf: leaf to be removed
     * @param proofSiblings: array of the sibling nodes of the proof of membership
     * @param proofPathIndices: path of the proof of membership
     * @return True or false.
     */
    function _verify(
        uint256 treeId,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) private view returns (bool) {
        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(proofPathIndices.length == _getDepth(treeId) && proofSiblings.length == _getDepth(treeId), "IncrementalBinaryTree: length of path is not correct");

        uint256 hash = leaf;

        for (uint8 i = 0; i < _getDepth(treeId); i++) {
        require(
            proofSiblings[i] < SNARK_SCALAR_FIELD,
            "IncrementalBinaryTree: sibling node must be < SNARK_SCALAR_FIELD"
        );

        if (proofPathIndices[i] == 0) {
            hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
        } else {
            hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
        }
        }

        return hash == _getRoot(treeId);
    }
}
