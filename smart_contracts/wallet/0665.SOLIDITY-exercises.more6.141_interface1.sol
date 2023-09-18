//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Test1 {
    string public myWord = "Nusaybin";

    function changeWord(string memory _word) external virtual {
        myWord = _word;
    }
}

//This is the base contract. We will interact with this from other two contract (142_... and 143_...)
//Virtual keyword looks like doesnt affect anything. It is used to tell people that this function can be overridden. 
//But tht thing is even I dont say anything, it doesnt affect anything at all.