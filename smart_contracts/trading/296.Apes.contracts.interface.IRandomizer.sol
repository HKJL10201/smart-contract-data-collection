// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity ^0.8.12;

interface IRandomizer {
    function getRandom(bytes memory seed, uint256 amount)
        external
        view
        returns (uint256[] memory, bool);
}
