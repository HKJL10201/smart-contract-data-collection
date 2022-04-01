//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract RetunMany {
    function assigned() public pure returns(string memory myWord, uint myNumber, bool myBool) {
        myWord = "Schwan";    
        myNumber = 5;
        myBool = true;
    }
    function returnMany() public pure returns(string memory, uint, bool) {
        return("Azad", 123, true);
    }
    function named() public pure returns(string memory myWord, uint myNumber, bool myBool) {
        return("Schékria", 444, true);
    }
}