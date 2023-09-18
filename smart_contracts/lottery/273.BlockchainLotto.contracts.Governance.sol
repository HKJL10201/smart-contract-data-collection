pragma solidity ^0.6.0;

contract Governance {
    uint256 public one_time;
    address public Lottery;
    address public Randomness;

    constructor() public {
    }

    function initLottery(address _lottery) external {
        require(_lottery != address(0), "no-lottery-address-given");
        Lottery = _lottery;
    }

    function initRandomness(address _randomness) external {
        require(_randomness != address(0), "governance/no-random-address");
        Randomness = _randomness;
    }
    
    function randomness() external view returns(address) {
        require(Randomness != address(0), "no-randomNumberConsumer-address-given");
        return Randomness;
    }

    function lottery() external view returns(address) {
        require(Lottery != address(0), "no-lottery-address-given");
        return Lottery;
    }
}


