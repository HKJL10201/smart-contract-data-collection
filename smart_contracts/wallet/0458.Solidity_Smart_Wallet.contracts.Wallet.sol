//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Wallet {
    uint public totalBalance;

    struct Transaction {
        uint timestamp;
        address to;
        address from;
        uint amount;
    }

    Transaction[] transactions;

    struct User {
        string name;
        uint balance;
        uint transactionCount;
        Transaction[] userTransactions;
    }

    mapping(address => User) users;


    function createUser (string memory _name) public returns(User memory){
        users[msg.sender].name = _name;
        return users[msg.sender];
    }

    function transfer (address _to, uint amount) public {
        require(amount <= users[msg.sender].balance, "Insufficient funds");
        User storage sender = users[msg.sender]; //find and store sender struct
        User storage receiver = users[_to]; //find and sotre receiver struct
        Transaction memory transferTransaction = Transaction(block.timestamp, _to, msg.sender, amount); 
        transactions.push(transferTransaction); //add new transfer to totalTransactions
        sender.balance -= amount; //subract amount from sender's balance
        receiver.balance += amount; //add amount to receiver's balance
        sender.userTransactions.push(transferTransaction); //add transaction to sender
        receiver.userTransactions.push(transferTransaction); //add transaction to receiver
        sender.transactionCount++; //increment transactionCount for sender
        receiver.transactionCount ++; //increment transactionCount for receiver
    }

    function deposit () public payable {
        require(msg.value>0, "deposit amount must be greater than 0");
        Transaction memory depositTransaction = Transaction(block.timestamp, address(this), msg.sender, msg.value);
        totalBalance += msg.value;
        transactions.push(depositTransaction);
        users[msg.sender].balance += msg.value;
        users[msg.sender].userTransactions.push(depositTransaction);
        users[msg.sender].transactionCount ++;
    }

    function withdraw (uint amount) public {
        require(amount <= users[msg.sender].balance, "Insufficient funds");
        bool withdrawSuccess = payable(msg.sender).send(amount);
        require(withdrawSuccess, "Oops! Withdraw failed. Try again later.");
        Transaction memory depositTransaction = Transaction(block.timestamp, msg.sender, address(this), amount);
        totalBalance -= amount;
        transactions.push(depositTransaction);
        users[msg.sender].balance -= amount;
        users[msg.sender].userTransactions.push(depositTransaction);
        users[msg.sender].transactionCount ++;
    }

    function getAllTransactions () public view returns(Transaction[] memory){
        return transactions;
    }

    function getUser (address addr) public view returns(User memory){
        return users[addr];
    }
    
}