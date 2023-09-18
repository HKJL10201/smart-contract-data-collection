// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract sampleContract{
    string public myString = "Hello world";

    function updateString(string memory _newString) public payable {
        if (msg.value == 1 ether){
        myString = _newString;
        }
    }
}