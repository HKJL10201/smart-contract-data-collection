//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

interface ITest1{
	function changeWord(string memory _word) external;
}

contract Test3 is ITest1 {

    string public myName = "Schkria";

    function changeWord(string memory _word) external override{
        myName = _word;
    }
    

}

//Here I am not changing the state on the Test1 contract.
//One difference between 142 and 143 is, in 142 I did not use "is" statement.
//The compiler first forces me to create a function same as in the interface,
//it forces me to put "override" as I am putting implementation.

/*
142 changes the state of 141 
143 does not change the state of 141

143 does not force me to use interface function
142 forces me to use interface function and also forces me to put implementation and also forces me to put "override"

143 does not have "is"
142 does have "is"

143 acts like standardizer
142 is a way of interacting and changing the state of another contract.