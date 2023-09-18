//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

//INTERFACE
interface IA {
    function changeWord(string memory a) external;
}

contract C {

    function foo(address otherContract, string memory x) external {
        IA(otherContract).changeWord(x);
    }

    //The state of A changes.
    //The state of C does not change.
    //import statement not used.
}