// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// an array can insert bytes32
library Bytes32Array {
    struct Array {
        bytes32[] _array;
    }

    function insert(Array storage self, bytes32 element) internal {
        self._array.push(element);
    }

    // remove first found element
    function remove(Array storage self, bytes32 element) internal {
        uint256 i;
        for (i; i < self._array.length; i++) {
            if (self._array[i] == element) {
                break;
            }
        }
        require(i < self._array.length, "Element not found");
        for (i; i < self._array.length - 1; i++) {
            self._array[i] = self._array[i + 1];
        }
        self._array.pop();
    }

    function get(Array storage self, uint256 index)
        internal
        view
        returns (bytes32)
    {
        require(index < self._array.length);
        return self._array[index];
    }

    function getAll(Array storage self)
        internal
        view
        returns (bytes32[] storage)
    {
        return self._array;
    }

    function length(Array storage self) internal view returns (uint256) {
        return self._array.length;
    }
}
