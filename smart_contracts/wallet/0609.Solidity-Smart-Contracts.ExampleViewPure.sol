// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract ExampleViewPure{

    uint public myStorageVariable;

    function getMyStorageVariable() public view returns(uint){ // View function can access storage variables outside of the scope of the function but it cant modify them
        return myStorageVariable;
    }

    function getAddition(uint a, uint b) public pure returns (uint){ // Pure function can only call the variables that are not storage variables
        return a+ b;
    }

    function setMyStorageVariable(uint _newvar) public returns(uint){
        myStorageVariable = _newvar;
        return _newvar;
    }
}