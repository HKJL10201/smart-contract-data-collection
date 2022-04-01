pragma solidity ^0.8.7;

contract SaveLottary {
    uint releasedNumber;
    
    function set(uint numberAdded) public {
        releasedNumber = numberAdded;
    }
    
    function get() public view returns (uint) {
        return releasedNumber;
    }
}