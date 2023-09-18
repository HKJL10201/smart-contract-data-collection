//SPDX-License-Identifier: MIT

pragma solidity >=0.8.18;

contract Apple {

    function foo() public {
        // Get the length of the calldata
        uint256 len = msg.data.length;
        
        // Access the first 32 bytes of the calldata (which represents the function selector)
        //To access the function selector from msg.data, you can use the bytes4 type to convert the first 4 bytes of msg.data into a function selector. 
        bytes4 selector = bytes4(msg.data[0:4]);
        
        // Access the second argument passed in the calldata
        uint256 arg2 = abi.decode(msg.data[4:], (uint256));
        
        // Do something with the arguments
        // ...
    }


}