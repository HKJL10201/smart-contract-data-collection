
//License
//SPDX-License-Identifier: GPL-3.0

//compiler version
pragma solidity 0.8.0;

//define the contract
contract Property{

    //variable
    int public value;

    //function
    function setValue(int _value) public{

        value = _value;
    }

}