//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Event1{

    //1.SIMPLE ENTRANCE 1
    //Events allow us to write data on the blockchain.
    //This data is tells that something happened on the blockchain.
    //Events are like state variables but cheaper. Smart contracts will not be able to retrieve the data.

    event LogSomething(string message, uint val);

    //This is a transaction function. It is not a normal function. 
    //Because we are storing new data on the blockchain. 
    //If we execute the function, these two parameters will be stored on the blockchain. 
    function example() external {
        emit LogSomething("function fired", 1);
    }
}

contract Event2 {
    //2. IMPROVED CONTRACT 2
    // Events can be fired by different accounts. And later if want to see who fired the function, we can 
    // either check one by one or we will create another event to log who fire the function. and here we
    // have to use "indexed" keyword. the second 
    event LogSomething(string message, uint val);
    event FunctionCallers(address indexed accounts, uint val);
    function example2() external {
        emit LogSomething("function fired", 1);
        emit FunctionCallers(msg.sender, 1);
    }
}


contract Event3 {
    //2. IMPROVED CONTRACT 3
    // Here we create a message contract. We will index  "address from" and "address to" parameters
    // to later check who sent what.
    event MessageApp(address indexed from, address indexed to, string message);
    function initiateMessageApp(address _to, string calldata _message) external {
        emit MessageApp(msg.sender, _to, _message);
    }
}

