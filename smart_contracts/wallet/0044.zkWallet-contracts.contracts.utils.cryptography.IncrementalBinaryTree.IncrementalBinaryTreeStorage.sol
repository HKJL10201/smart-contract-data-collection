// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library IncrementalBinaryTreeStorage {
    struct IncrementalTreeData {
        uint8 depth;
        uint256 root;
        uint256 numberOfLeaves;
        mapping(uint256 => uint256) zeroes;
        mapping(uint256 => uint256[2]) lastSubtrees;
    }

    struct Layout {
         mapping(uint256 => IncrementalTreeData) trees;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.IncrementalBinaryTree");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setDepth(
        Layout storage s,
        uint256 treeId,
        uint8 depth
    ) internal {
        s.trees[treeId].depth = depth;
    }

    function setRoot(
        Layout storage s,
        uint256 treeId,
        uint256 root
    ) internal {
        s.trees[treeId].root = root;
    }

    function setNumberOfLeaves(Layout storage s, uint256 treeId) internal {
        s.trees[treeId].numberOfLeaves += 1;
    }

    function setZeroes(
        Layout storage s,
        uint256 treeId,
        uint256 leafIndex,
        uint256 zeroValue
    ) internal {
        s.trees[treeId].zeroes[leafIndex] = zeroValue;
    }
}
