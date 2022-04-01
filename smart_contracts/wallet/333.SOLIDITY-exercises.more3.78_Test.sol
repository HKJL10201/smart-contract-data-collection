//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract ArrayOperations {
    //create a dynamic size array
    uint[] myArray;

    // WAY-1 Adding elements
    function addArray(uint a, uint b, uint c, uint d, uint e) external {
        myArray = [a, b, c, d, e];
    }
    
    // This way will remove the element but values INDEXES WILL BE MIXED. Last element will 
    // change place with target element. Target element will then be removed.
    // This way can be used if the index of values is not important
    function removeArray2(uint x) public {
        uint lastElIndex = myArray.length - 1;
        myArray[x] = myArray[lastElIndex];
        myArray.pop();
    }

    //This is a regular return for dynamic array
    // Returning a big array can drain all your gas. Keep this in mind in production.
    function getArray() external view returns(uint[] memory) {
        return myArray;
    }

    //Here is how you write a test for your function
    function testRemove2() external {
        myArray = [1,2,3,4];
        removeArray2(1);
        assert(myArray.length == 3);
        assert(myArray[0] == 1);
        assert(myArray[1] == 4);
        assert(myArray[2] == 3);

        removeArray2(1);
        assert(myArray.length == 2);
        assert(myArray[0] == 1);
        assert(myArray[1] == 3);

    }
}