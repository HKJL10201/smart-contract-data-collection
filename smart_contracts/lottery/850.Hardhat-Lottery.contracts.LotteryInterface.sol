// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface LotteryInterface {
    function getState() external view returns (bool);

    function getPlayerCounter() external view returns (uint256);

    function getLatestCheckpoint() external view returns (uint256);

    function getInterval() external view returns (uint256);

    function getRandomNumber() external view returns (uint256);

    function requestRandomWinner() external;

    function pickRandomWinner() external;
}
