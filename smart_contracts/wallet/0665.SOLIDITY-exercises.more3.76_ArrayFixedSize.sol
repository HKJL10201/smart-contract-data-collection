//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract FixedSize {
    //create a fixed size array
    uint[3] myArray;

    // When you create a fixed-size array you cannot use push method.
    // Because fixed-size array already has values. I mean above array
    // might look empty but actually it is not empty. Its values are: [0, 0, 0]
    // For this reason, you cannot push. Because "push" means it will have 4th element,
    // which it cannot. Thats why you can only update values like below.
    function addArray(uint a, uint b, uint c) external {
        myArray = [a, b, c];
    }

    // Updating array
    function updateArray(uint x) external {
        myArray[1] = x;
    }

    // POP AND DELETE
    // Pop removes last element and shrinks the size of array by 1.
    // As our array is fixed-size, we cannot use "pop" to remove element, it will give error.
    // But we can use delete, because length is not going to change. delete method will 
    // return the element to its default value which is "0" in uint case.
    function deleteArray(uint m) external {
        delete myArray[m];
    }


    // Memory arrays with fixed length can be created using the "new" operator. 
    // As opposed to storage arrays, it is not possible to resize memory arrays
    // (e.g. the .push member functions are not available). Be careful how you add values
    // to the array.
    function memoryArray(uint _n, uint _m, uint _k) external pure returns(uint[] memory) {
        uint[] memory a = new uint[](3);
        a[0] = _n;
        a[1] = _m;
        a[2] = _k;
        return a;
    }
    // here is the second way to initialize a fixed-size array in memory, add value to it
    // and then return it. Returning array can drain all the gas. So, be sure to return small arrays only.
    function memoryArray2(uint _n, uint _m, uint _k) external pure returns(uint[3] memory) {
        uint[3] memory a = [_n, _m, _k];
        return a;
    }


    // This is how you return an array with fixed size.Look at return
    // Returning array can drain all the gas. So, be sure to return small arrays only.
    function getArray() external view returns(uint[3] memory) {
        return myArray;
    }

}