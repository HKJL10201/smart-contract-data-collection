// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract ExampleMapping {

    mapping(uint => bool) public myMapping;
    mapping (address => bool) public myAddressMapping;
    mapping(uint => mapping (uint => bool)) public uintUnitBoolMapping;

    function setValue(uint _index) public {
        myMapping[_index] = true;
    }

    function setMyAddressToTrue() public {
        myAddressMapping[msg.sender] = true;
    }

    function setUintUnitBooleanMapping(uint _key1, uint _key2, bool _value) public {
        uintUnitBoolMapping[_key1][_key2] = _value;

    }
}
