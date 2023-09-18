// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

library Bitwise {
  uint256 constant private M1 = 0x0000000000000000000000000000000000000000000000005555555555555555;
  uint256 constant private M2 = 0x0000000000000000000000000000000000000000000000003333333333333333;
  uint256 constant private M4 = 0x0000000000000000000000000000000000000000000000000F0F0F0F0F0F0F0F;


  /// @dev Returns amount of set bits, only works with uint64s
  function _popCount(uint256 x) internal pure returns (uint256 pop_) {
    x -= (x >> 1) & M1;
    x = (x & M2) + ((x >> 2) & M2);
    x = (x + (x >> 4)) & M4;
    x += x >>  8;
    x += x >> 16;
    x += x >> 32;
    return x & 0x7f;
  }
}