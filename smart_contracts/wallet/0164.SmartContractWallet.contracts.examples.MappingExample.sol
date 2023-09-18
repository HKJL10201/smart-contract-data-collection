//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Simple example of how mappings work in Sol.
contract MappingExample {
    mapping(uint => bool) public myMapping;
    mapping(address => bool) public myAddressMapping;

    // Set a value for the mapping to determine a true/false result.
    // In this example, we just assign a uint and it will return true.
    function setValue(uint _index) public {
        myMapping[_index] = true;
    }

    // Same applies as above without a parameter. We are simply assigning an address to 
    // relevant variable and it will return true.
    function setAddress() public {
        myAddressMapping[msg.sender] = true;
    }

    // Double Mapping Example
    mapping(uint => mapping(uint => bool)) public uIntUintBoolMapping;

    function setUintUintBoolMapping(uint _index, uint _index2, bool _value) public {
        uIntUintBoolMapping[_index][_index2] = _value;
    }
}