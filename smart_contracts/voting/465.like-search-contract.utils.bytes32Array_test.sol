// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./bytes32Array.sol";

contract Bytes32ArrayTest {
    using Bytes32Array for Bytes32Array.Array;
    Bytes32Array.Array array;

    function insert(bytes32 element) public {
        array.insert(element);
    }

    function remove(bytes32 element) public {
        array.remove(element);
    }

    function get(uint256 index) public view returns (bytes32) {
        return array.get(index);
    }

    function getAll() public view returns (bytes32[] memory) {
        return array.getAll();
    }
}
