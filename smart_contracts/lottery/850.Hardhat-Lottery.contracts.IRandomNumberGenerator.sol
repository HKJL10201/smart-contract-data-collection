// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IRandomNumberGenerator {
    function getRandomNumber(uint256 _requestId) external view returns (uint256);

    function requestRandomWords() external returns (uint256);
}
