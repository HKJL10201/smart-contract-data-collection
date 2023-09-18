pragma solidity ^0.4.17;

// Recall that:
// Storage and memory:
// 1) Sometimes references where our contract stores data
// 2) Sometimes references how our solidity variables
//    store values.
contract Numbers {
    int[] public numbers;

    function Numbers() public {
        numbers.push(20);
        numbers.push(32);

        // int[] storage myArray = numbers;

        // when using the 'storage' keyword changes the
        // way the folowing variable works.
        // The myArray variable now points to the same
        // array in storage as the 'numbers' array
        // points to.

        // Instead of storage we can instead use
        // 'memory' keyword to instantiate a different
        // array, where myArray will now point to
        // the array in memory, designated by 'memory'

        // storage = pretty much like a computer's hard drive
        // memory = pretty much like a computer's RAM

        // Passed in the numbers array, then modified the
        // the numbers array, but we made changes to a *copy*
        // because taking in arguments into function-like variables
        // are assumed to be stored in 'memory'

        // Thus, whenever you take in function arguments, they are
        // automatically assumed to be memory type variables.

        changeArray(numbers);
    }

    // Adding a new simple array

    // Right now, we are not calling 'changeArray' in any way
    // shape or form.

    // If we create a new instance of this contract, the function
    // will not be invoked.

    // Now that we include the 'storage' keyword, it changes
    // how we are passing around referenes to these data structures

    //
    function changeArray(int[] storage myArray) private {
        // taking the first element in the array and setting to 1
        myArray[0] = 1;
    }

    // 'storage' and 'memory' keywords changes how we are pass around
    // references of data structures


}
