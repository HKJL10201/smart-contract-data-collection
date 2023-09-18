// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive number if `_b` is smaller.
    function compare(string memory _a, string memory _b) pure internal returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length < b.length)
            return -1;
        if (a.length > b.length)
            return 1;
        for (uint i = 0; i < a.length; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b) pure internal returns (bool) {
        return compare(_a, _b) == 0;
    }
}
