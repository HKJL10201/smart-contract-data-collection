//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// A small "real world" example of mappings.
contract MappingExampleWithdrawls {
    mapping(address => uint) public balanceReceived;

    // Increment the variable value when you send money.
    function sendMoney() public payable {
        balanceReceived[msg.sender] += msg.value;
    }

    // After sending money, we can now obtain the balance of the address and return
    // a uint result.
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // Withdraw money from the contract using the Checks, Effects, Interactions Pattern.
    // Details of pattern: https://fravoll.github.io/solidity-patterns/checks_effects_interactions.html
    function withdrawAllMoney(address payable _to) public {
        // Checks
        //require(balanceReceived[msg.sender] >= amount);
        uint balanceToSend = balanceReceived[msg.sender];

        // Effects
        balanceReceived[msg.sender] = 0;

        // Interactions
        _to.transfer(balanceToSend);
        // msg.sender.transfer(amount);
    }
}