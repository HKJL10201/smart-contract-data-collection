pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
contract MinimumViableToken {
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(uint256 initialSupply) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        assert(balanceOf[msg.sender] >= _value);             // Check if the sender has enough
        assert(balanceOf[_to] + _value >= balanceOf[_to]);   // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
    }
}
