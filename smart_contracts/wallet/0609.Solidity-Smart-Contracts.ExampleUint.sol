// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract ExampleUint {
    uint256 public myUint; // 0 - (2^256) - 1
    
    uint8 public  myUint8 = 250;

    int public myInt = -10;

    function setMyUint(uint _myUint) public {
        myUint = _myUint;
    }

    function increementUint8() public {
        myUint8++;
    }

    function decreementUnit() public {
        myUint--;
    }

    function increementInt() public {
        myInt++;
    }
}