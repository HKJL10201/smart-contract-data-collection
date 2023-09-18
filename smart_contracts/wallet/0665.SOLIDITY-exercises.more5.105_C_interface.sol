//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

interface IA {
    function myWord() external view returns(string memory);
    function changeWord() external;
}

contract C {
    function call1(address otherContract) external view returns(string memory){
        return IA(otherContract).myWord();
    }
    function call2(address otherContract) external {
        IA(otherContract).changeWord();
    }
}