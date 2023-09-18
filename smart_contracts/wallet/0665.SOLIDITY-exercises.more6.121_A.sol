//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract A {
    string public myWord = "Nusaybin";

    function changeWord(string memory a) external {
        myWord = a;
    }
}

/*

                        1) Import-inheritance
                        2) Interface
                        3) regular Function Call
                        4) call method - abi.encodeWithSignature
                        5) call method - abi.encodeWithSelector
                        6) delegatecall method - abi.encodeWithSignature
                        7) delegatecall method - abi.encodeWithSelector
 

---STATE OF A CHANGES----
2) Interface
3) regular Function Call
4) call method - abi.encodeWithSignature
5) call method - abi.encodeWithSelector

----STATE OF B CHANGES----
1) Import-inheritance
6) delegatecall method - abi.encodeWithSignature
7) delegatecall method - abi.encodeWithSelector

----IMPORT STATEMENT IS USED----
1) Import-inheritance
3) regular Function Call
5) call method - abi.encodeWithSelector
7) delegatecall method - abi.encodeWithSelector

 */