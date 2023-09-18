// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract ExampleWrapAround {
    uint256 public myUint; // 0 - (2^256) - 1
    
    uint8 public  myUint8 = 250;


    function setMyUint(uint _myUint) public {
        myUint = _myUint;
    }

    function increementUint8() public {
        myUint8++;
    }

    function decreementUnit() public {
        unchecked {
        myUint--;
        } 
    }

}