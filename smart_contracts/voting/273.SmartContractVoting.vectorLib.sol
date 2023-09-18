// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library vectorLib {
    function dot (int256[] memory a, int256[] memory b) public pure returns (int256) {
        require(a.length == b.length, "Different Length");
        int256 result = 0;
        for (uint i = 0; i < a.length; i++) {
            result += a[i] * b[i];
        }
        return result;
    }
}