// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {ECPoint, ECPointLib} from "./ECPointLib.sol";

library UIntLib {
    // Pre-computed constant for 2 ** 255
    uint256 private constant U255_MAX_PLUS_1 =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function modP(uint256 a) internal pure returns (uint256) {
        return a % ECPointLib.P;
    }

    function modQ(uint256 a) internal pure returns (uint256) {
        return a % ECPointLib.Q;
    }

    function isZero(uint256 a) internal pure returns (bool) {
        return modP(a) == 0;
    }

    function equals(uint256 a, uint256 b) internal pure returns (bool) {
        return modP(a) == modP(b);
    }

    function add(
        uint256 a,
        uint256 b,
        uint256 p
    ) internal pure returns (uint256) {
        return addmod(a, b, p);
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mulmod(a, b, ECPointLib.P);
    }
}
