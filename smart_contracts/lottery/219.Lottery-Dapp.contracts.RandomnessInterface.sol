pragma solidity ^0.6.5;

interface RandomnessInterface {
    function getRandomNumber() external returns (bytes32);
}
