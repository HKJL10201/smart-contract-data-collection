pragma solidity ^0.5.7;

contract BondingManagerMock {

    uint64 public unbondingPeriod;

    constructor(uint64 _unbondingPeriod) public {
        unbondingPeriod = _unbondingPeriod;
    }
}
