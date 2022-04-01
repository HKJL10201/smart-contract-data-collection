// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract functools {
    function sliceAddressAry(
        uint256 start,
        uint256 end,
        address[] memory ary
    ) internal pure returns (address[] memory slice_) {
        uint256 index = 0;
        while (start <= end) {
            slice_[index] = ary[start];
            start += 1;
            index += 1;
        }
    }
    function sliceStringAry(
        uint256 start,
        uint256 end,
        string[] memory ary
    ) internal pure returns (string[] memory slice_) {
        uint256 index = 0;
        while (start <= end) {
            slice_[index] = ary[start];
            start += 1;
            index += 1;
        }
    }
}
