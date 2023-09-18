//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract ArrayInArray {

    //How to accept array [blue, black, red, green] as parameter?
    //WAY-1
    string[][] public myArray;
    string[] parameterArray = ["blue", "black", "red", "green"];
    string[] b = ["a", "b", "c", "d"];
    function addArray() external {
        myArray.push(parameterArray);
        myArray.push(b);

    }
    function returnArray() external view returns(string[][] memory) {
        return myArray;
    }


    // WAY-2
    string[][] public myArray2;
    
    function addArray2(string[] memory x)  external {
        myArray2.push(x);
    }
    function returnArray2() external view returns(string[][] memory) {
        return myArray2;
    }



}