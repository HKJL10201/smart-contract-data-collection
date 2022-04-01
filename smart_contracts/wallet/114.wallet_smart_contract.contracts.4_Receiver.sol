//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Receiver {
    event Deposit(address indexed sender, uint amount);

    fallback() external payable{
        emit Deposit(msg.sender, msg.value);
    }
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}
