// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "../utils/Arrays256.sol";

contract Arrays256Impl {
    using Arrays256 for uint256[];

    uint256[] private _array;

    constructor (uint256[] memory array) public {
        _array = array;
    }

    function heapSort() external {
        _array.heapSort();
    }

    function getArray() external view returns (uint256[] memory) {
        return _array;
    }
}
