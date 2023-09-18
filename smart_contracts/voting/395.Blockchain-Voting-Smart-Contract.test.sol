// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.0;

contract Test{
    function summation(uint n) public returns(uint){
        uint sum = 0;

        for(uint i=0; i<=n; i++){
            sum += i;
        }

        return sum;
    }
}