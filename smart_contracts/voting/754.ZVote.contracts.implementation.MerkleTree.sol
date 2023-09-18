// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

uint256 constant TREE_DEPTH = 21;

abstract contract MerkleTree {
    mapping(uint256 => uint256)[TREE_DEPTH] internal tree;
    uint256 public size = 0;

    function addElement(uint256 x) internal {
        // input element in the tree
        tree[TREE_DEPTH-1][size] = x;
        // update the tree
        uint256 index = size;
        for (uint256 d = TREE_DEPTH-1; d > 0; d--) {
            if (index % 2 == 0)
                tree[d][index+1] = tree[d][index];
            index /= 2;
            tree[d-1][index] = hashFunction(
                tree[d][2*index], 
                tree[d][2*index+1]
            );
        }
        size += 1;
    }

    function merkleRoot() public view returns (uint256) {
        require(size > 0, "tree is empty");
        return tree[0][0];
    }

    function getElementAt(uint256 i) public view returns (uint256) {
        require(i < size, "index out of range");
        return tree[TREE_DEPTH-1][i];
    }

    function hashFunction(
        uint256 a, uint256 b
    ) internal view virtual returns (uint256);

}