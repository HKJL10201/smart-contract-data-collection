//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract A {
    function getWord() external pure virtual returns(string memory) {
        return "Good morning";
    }
}

contract B is A {
    function getWord() external pure virtual override returns(string memory) {
        return "Good afternoon";
    }
}

contract C is A {
    function getWord() external pure virtual override returns(string memory) {
        return "good evening";
    }
}

contract D is C{
    function getWord() external pure virtual override returns(string memory) {
        return "good night";
    }
}
/* MULTI INHERITANCE FUNCTIONS:
Here we will add a simple parantheses for overrride and write the names of the contract
we inherit. And no need for "virtual" here as no other function will inherit from this*/

contract E is B, D {
    function getWord() external pure override(B, D) returns(string memory) {
        return "good day";
    }
}

/*COMMENT
Actually I dont understand the use this override. Because instead of overriding maybe I can create a new function*/