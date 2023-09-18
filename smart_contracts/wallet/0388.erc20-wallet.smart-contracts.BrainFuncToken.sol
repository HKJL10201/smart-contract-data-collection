pragma solidity ^0.4.24;

import "./StandardToken.sol";

contract BrainFuncToken is StandardToken {

    string public name = "BrainFunc Token";
    string public symbol = "BFT";
    uint8 public decimals = 18;
    uint256 public INITIAL_SUPPLY = 100000000 * 1 ether;

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
}
