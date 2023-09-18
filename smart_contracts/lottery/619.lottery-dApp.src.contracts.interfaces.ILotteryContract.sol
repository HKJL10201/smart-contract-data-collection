// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.8.0;

interface ILotteryContract {
    function fulfillRandomNumber(uint) external;
}