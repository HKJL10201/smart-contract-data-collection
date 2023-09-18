pragma solidity ^0.6.5;

interface LotteryInterface {
    function finalizeRound(uint256 _randomNumber) external;
}
