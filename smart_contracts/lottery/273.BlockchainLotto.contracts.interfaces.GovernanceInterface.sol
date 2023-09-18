pragma solidity ^0.6.0;

interface GovernanceInterface {
    function initLottery(address lottery) external;
    function initRandomness(address randomness) external;

    function randomness() external returns(address);
    function lottery() external returns(address);
}
