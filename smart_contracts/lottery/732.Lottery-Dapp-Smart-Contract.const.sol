// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0 < 0.9.0;

contract test
{
    //constructor in solidity

    //initializing and declaring variable without constructor
    uint age; //initializing variable
    age = 10; //compile time error

    //initializing and declaring variable with constructor

    uint age;
    constructor()
    {
        age = 10;
    }

}