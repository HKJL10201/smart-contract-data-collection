//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract DataLocationTest {
    //When you declare a DYNAMIC VARIABLE, you need to state its 
    // data location: storage, memory, calldata

    //STORAGE: means the variable is a state variable
    //MEMORY: means 
    //CALLDATA: it is like memory but it can only be used for function inputs.


    string myWord;
    //Here I can say memory but calldata is a little cheaper. But I dont quite understand
    // under what conditions I need to use calldata or memory.
    function setMyWord(string calldata _text) external {
        myWord = _text;
    }

    // Here if I change "memory" to "calldata" it will give error. I dont know why.
    function getMyWord() external view returns(string memory) {
        return myWord;
    }


}