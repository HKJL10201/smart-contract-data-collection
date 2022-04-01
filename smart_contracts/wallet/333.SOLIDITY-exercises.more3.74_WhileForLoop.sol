//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Example {
    // declaring a state variable
    uint i = 0;

    //Declare the array
    uint[] myArray;

    //Create function to values to array - use While Loop
    function addArray() external {
        while(i<10) {
            myArray.push(i);
            i++;
        }
    }
    //Create function to view array
    function getArray() external view returns(uint[] memory) {
        return myArray;
    }

    //Create function to values to array - use For Loop
    function addArray2() external {
        for (uint x = 0; x<10; x++) {
            myArray.push(x);
        }
    }
}


