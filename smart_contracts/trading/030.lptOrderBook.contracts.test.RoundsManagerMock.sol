pragma solidity ^0.5.1;

contract RoundsManagerMock {

    uint256 public roundLength;

    constructor(uint256 _roundLength) public {
        roundLength = _roundLength;
    }
}
