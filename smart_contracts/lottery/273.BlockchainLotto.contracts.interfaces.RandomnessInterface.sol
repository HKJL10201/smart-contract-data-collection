pragma solidity ^0.6.0;

interface RandomnessInterface {
    function getRandomNumber(uint256 userProvidedSeed) external returns (bytes32 requestId);
}

