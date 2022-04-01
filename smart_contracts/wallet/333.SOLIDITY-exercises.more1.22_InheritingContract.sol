pragma solidity >=0.8.7;

import "./14_DataTypes.sol";

//this exercise is to practice Inheritance

contract Inheriting is DataTypes {

    function newValue() public {
        stringMes = "changed content";
    }

    function callFunction() external view {
        getVariables();
    }
    
}