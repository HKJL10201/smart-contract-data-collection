// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITreasury {
    function _moduleDeposit() external payable returns (bool);
}
