pragma solidity ^0.5.16;

import "./owned.sol";

contract mortal is owned {
    function kill() public {
        if (msg.sender == owner) selfdestruct(msg.sender);
    }
}
