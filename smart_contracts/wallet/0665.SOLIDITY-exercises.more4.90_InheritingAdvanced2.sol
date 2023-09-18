//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract A {
    string public myword = "Hello";
}

contract B is A {
    string public myword2 = "good morning";
}

contract C is A {
    bytes32 public myword3 = "hello";
}

contract D is C{
    address public myAddress = msg.sender;
}
/* MULTI INHERITANCE
Here I must first say B and then D. Because B is more base-like than D.
B is child of only A, while D is child of C and A.*/
contract E is B, D {
    uint256 public myNumber = 2552255252;
}