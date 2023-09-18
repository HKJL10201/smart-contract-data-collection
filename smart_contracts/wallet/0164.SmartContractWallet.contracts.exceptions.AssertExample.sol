//SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

// This example uses a lower pragma version for the purposes of the example, but it 
// is always a good idea to have input validation in place.
contract AssertExample {
    mapping(address => uint8) public balanceReceived;
    
    function deposit() public payable {
        // Smart contracts should never reach a state of panic, where an assert is essentially required.
        assert(msg.value == uint8(msg.value));
        balanceReceived[msg.sender] += uint8(msg.value);
    }

    // Using require ensures the logical comparison has been met. 
    // "require" will use gas and anything remaining will be returned.
    function withdrawl(address payable _to, uint8 _amount) public {
        require(_amount <= balanceReceived[msg.sender], "Insuffienct funds, aborting!");
        balanceReceived[msg.sender] -= _amount;
        _to.transfer(_amount);
    }
}