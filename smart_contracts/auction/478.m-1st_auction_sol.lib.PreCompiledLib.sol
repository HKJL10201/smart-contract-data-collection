// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library PreCompiledLib {
    function bn128Add(
        uint256 ax,
        uint256 ay,
        uint256 bx,
        uint256 by
    ) internal view returns (uint256[2] memory result) {
        uint256[4] memory input = [ax, ay, bx, by];
        assembly {
            if iszero(staticcall(not(0), 0x06, input, 0x80, result, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function bn128ScalarMul(
        uint256 x,
        uint256 y,
        uint256 scalar
    ) internal view returns (uint256[2] memory result) {
        uint256[3] memory input = [x, y, scalar];
        assembly {
            if iszero(staticcall(not(0), 0x07, input, 0x60, result, 0x40)) {
                revert(0, 0)
            }
        }
    }
}
