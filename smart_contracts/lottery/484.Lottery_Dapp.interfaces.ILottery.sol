// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface ILottery {

    function fulfillRandom(uint, bytes32) external;

}