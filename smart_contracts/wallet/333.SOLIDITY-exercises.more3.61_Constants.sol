//SPDX-Licence-Identifier: MIT

pragma solidity >= 0.8.7;

contract MyConstants {
    uint public constant a = 5; // execution cost: 21371 gas
    uint public b = 5; // execution cost: 23493 gas

    // So, if value of a state variable is stable, in other words if it wont change
    // then better to tag it as constant to save on gas. You can use this for address
    // strings and other data types.

}