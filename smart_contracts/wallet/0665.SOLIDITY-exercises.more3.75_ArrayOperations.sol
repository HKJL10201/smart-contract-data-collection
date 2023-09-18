//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract ArrayOperations {
    //create a dynamic size array
    uint[] myArray;

    // WAY-1 Adding elements
    function addArray(uint a, uint b, uint c) external {
        myArray = [a, b, c];
    }

    // WAY-2 Adding elements
    function addArray2(uint d) external {
        myArray.push(d);
    }

    // Updating array
    function updateArray(uint x) external {
        myArray[1] = x;
    }

    // POP AND DELETE
    // Pop removes last element and shrinks the size of array by 1.
    function popArray() external {
        myArray.pop();
    }   

    // Delete does not remove the element, it returns it to its 
    // default value which is "0" in uint[] case. So, array length remains the same.
    function deleteArrayElement(uint m) external {
        delete myArray[m];
    }

    //This is a regular return for dynamic array
    // Returning a big array can drain all your gas. Keep this in mind in production.
    function getArray() external view returns(uint[] memory) {
        return myArray;
    }
}