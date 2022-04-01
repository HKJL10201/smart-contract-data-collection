// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./redBlackTree.sol";

// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a - Contract for testing
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2019. The MIT Licence.
// ----------------------------------------------------------------------------
contract RedBlackTreeTest {
    using RedBlackTree for RedBlackTree.Tree;

    RedBlackTree.Tree tree;

    function root() public view returns (uint256 _key) {
        _key = tree.root;
    }

    function total() public view returns (uint256 _count) {
        _count = tree.total;
    }

    function first() public view returns (uint256 _key) {
        _key = tree.first();
    }

    function last() public view returns (uint256 _key) {
        _key = tree.last();
    }

    function next(uint256 key) public view returns (uint256 _key) {
        _key = tree.next(key);
    }

    function prev(uint256 key) public view returns (uint256 _key) {
        _key = tree.prev(key);
    }

    function exists(uint256 key) public view returns (bool _exists) {
        _exists = tree.exists(key);
    }

    function isEmptyTree() public view returns (bool _emptyTree) {
        _emptyTree = tree.isEmptyTree();
    }

    function getNode(uint256 _key)
        public
        view
        returns (
            uint256 key,
            uint256 parent,
            uint256 left,
            uint256 right,
            bool red
        )
    {
        (key, parent, left, right, red) = tree.getNode(_key);
    }

    function getAt(uint256 _index, bool _descending)
        public
        view
        returns (uint256)
    {
        return tree.getAt(_index, _descending);
    }

    function getBatch(uint256 _fromIndex, uint8 _size ,bool _descending)
        public
        view
        returns (uint256[] memory array)
    {
        return tree.getBatch(_fromIndex, _size, _descending);
    }

    function getIndex(uint256 _key, bool _descending)
        public
        view
        returns (bool found, uint256 index)
    {
        (found, index) = tree.getIndex(_key, _descending);
    }

    function insert(uint256 _key) public {
        tree.insert(_key);
    }

    function remove(uint256 _key) public {
        tree.remove(_key);
    }
}
