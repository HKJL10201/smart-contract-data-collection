//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract A {
    string public myWord = "schkria";

    function changeWord() external virtual {
        myWord = "mencce";
    }

}

//OR You can place above contract in another file and use import statement.

contract D is A {
    function changeWord() external override {
        myWord = "nusaybin";
    }
}
