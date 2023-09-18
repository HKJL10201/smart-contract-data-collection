//SPDX-License-Identifier: MIT

pragma solidity >=0.8.18;

contract Apple {

    

    function foo() public view returns (uint) {
        assembly {
            let value := sload(num.slot)
            mstore(0x0, value)
            return(0x0, 0x20)
        }
    }
    uint internal num = 6;
    function foo1() public view returns (uint) {
        uint value = num;
        assembly {
            mstore(0x0, value)
            return(0x0, 0x20)
        }
    }

    function foo2() public pure returns (string memory) {
        assembly {
            let c := "hello world" 
            mstore(0x0, c)
            return(0x0, 0x20)
        }
    }
    function foo3() public pure returns (string memory) {
        string memory c = "hello world";
        bytes memory b = bytes(c);
        uint256 len = b.length;
        uint256 ptr;
        assembly {
            ptr := mload(0x40)
            mstore(ptr, len)
            mstore(add(ptr, 0x20), len)
            mstore(add(ptr, 0x40), add(b, 0x20))
        }
        bytes memory outputBytes = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            outputBytes[i] = b[i];
        }
        return string(outputBytes);
    }
    function foo4() public pure returns (string memory) {
        string memory d = "hello world";
        return d;
    }

    /*
    sload() : loads a value from storage to EVM register. 
        (EVM Register: an exlusive data location used by EVM for contract execution. 
        It is a memory location but not the main memory)

    mstore(): loads a value from EVM Register to the main/free memory. OR
              loads a value from stack memory to EVM register and then to main/free memory.
              cannot load a value from contract storage.    
    */
}


