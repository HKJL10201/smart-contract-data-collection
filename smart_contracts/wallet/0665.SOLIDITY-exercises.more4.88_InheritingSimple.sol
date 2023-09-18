//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract A {
    string myword = "Schwan";
}

contract B is A{
    string herword = "Schkria";
}

contract C is B {
    string theirword = "agitow";
    function returnWord() external view returns(string memory) {
        return myword;
    }
    function updateWord() external {
        myword = "Mence";
    }
}