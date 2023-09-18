// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IRamdomNumber {
    function getRandomNumber() external returns(bytes32 requestId);
    function setUntil(uint _until) external;
    function randomResult() external view returns(uint256);
    function lastRequestId() external view returns(bytes32);
}