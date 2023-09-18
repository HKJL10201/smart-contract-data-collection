//SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

// This example uses a lower pragma version for the purposes of the example, but it 
// is always a good idea to have imput validation in place.
contract RequireExample {
    mapping(address => uint) public balanceReceived;
    
    function deposit() public payable {
        balanceReceived[msg.sender] += msg.value;
    }

    // Using require ensures the logical comparison has been met. 
    // "require" will use gas and anything remaining will be returned.
    function withdrawl(address payable _to, uint _amount) public {
        require(_amount <= balanceReceived[msg.sender], "Insuffienct funds, aborting!");
        balanceReceived[msg.sender] -= _amount;
        _to.transfer(_amount);
    }
}