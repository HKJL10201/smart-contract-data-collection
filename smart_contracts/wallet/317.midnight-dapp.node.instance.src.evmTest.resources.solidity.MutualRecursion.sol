pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
contract MutualRecursion {

    function isEven(uint n) public returns (bool) {
        if (n == 0)
            return true;
        else
            return isOdd(n - 1);
    }

    function isOdd(uint n) public returns (bool) {
        if (n == 0)
            return false;
        else
            return isEven(n - 1);
    }
}
