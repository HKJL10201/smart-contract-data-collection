//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// A "real-world" example of how to combine the use of mappings and structs and how to access
// a mapping when managing relevant items in a struct.
contract MappingStructExample {

    struct Transaction {
        uint amount;
        uint timestamp;
    }

    struct Balance {
        uint totalBalance;
        uint numDeposits;
        mapping(uint => Transaction) deposits;
        uint numWithdrawls;
        mapping(uint => Transaction) withdrawls;
    }

    mapping(address => Balance) public balances;

    function getDeposit(address _from, uint _numDeposit) public view returns(Transaction memory) {
        return balances[_from].deposits[_numDeposit];
    }

    function depositMone() public payable {
        balances[msg.sender].totalBalance += msg.value;

        Transaction memory deposit = Transaction(msg.value, block.timestamp);
        balances[msg.sender].deposits[balances[msg.sender].numDeposits] = deposit;
        balances[msg.sender].numDeposits++;
    }

    function withdrawMoney(address payable _to, uint _amount) public {
        balances[msg.sender].totalBalance -= _amount;

        Transaction memory withdrawl = Transaction(_amount, block.timestamp);
        balances[msg.sender].deposits[balances[msg.sender].numDeposits] = withdrawl;
        balances[msg.sender].numWithdrawls++;

        _to.transfer(_amount);
    }
}