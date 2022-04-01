//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract A {
    string public myWord = "schkria";

    function changeWord() external virtual {
        myWord = "mencce";
    }

}