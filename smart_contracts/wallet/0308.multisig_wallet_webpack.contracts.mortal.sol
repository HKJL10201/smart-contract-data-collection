pragma solidity ^0.4.0;

import "./owned.sol";

// inherit from `owned` contract
contract mortal is owned {
    function kill() {
        if (msg.sender == owner) {
            selfdestruct(owner);
        }
    }
}
