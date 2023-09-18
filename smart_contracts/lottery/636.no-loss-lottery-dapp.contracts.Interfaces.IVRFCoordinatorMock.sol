// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IVRFCoordinator{
    function callBackWithRandomness(bytes32 requestId,uint256 randomness,address consumerContract) external;
}