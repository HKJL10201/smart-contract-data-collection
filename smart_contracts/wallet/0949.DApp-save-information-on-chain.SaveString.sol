// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SaveString {

    // This mapping allows to associate an address with a string
    mapping(address => string) public savedStrings;


    // Function to save a string into the mapping with the address calling the function
    function saveString(string memory _string) public {
        savedStrings[msg.sender] = _string;
    }

    // Function to retrieve a string from the mapping, based on what address is calling it
    function getString() public view returns(string memory) {
        return savedStrings[msg.sender];
    }
}
