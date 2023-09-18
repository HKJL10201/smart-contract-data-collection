// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.8.0;

interface IRandomnessContract {
    function randomNumber(uint) external returns (bytes32);
    //function getRandom(uint, uint) external;
}