// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.8.0;

contract GovernanceContract {
    uint8 public numberOfTimesLoaded;
    address public lottery;
    address public randomness;
    
    constructor() public {
        numberOfTimesLoaded = 1;
    }
    function init(address _lottery, address _randomness) public {
        require(_randomness != address(0), "governance/no-randomnesss-address");
        require(_lottery != address(0), "no-lottery-address-given");
        require(numberOfTimesLoaded > 0, "can-only-be-called-once");
        numberOfTimesLoaded = numberOfTimesLoaded - 1;
        randomness = _randomness;
        lottery = _lottery;
    }
}