//SPDX-Licence-Identifier: MIT

pragma solidity >=0.8.7;

contract ForLoop2 {
    function findSum(uint _n) external pure returns(uint) {
        uint totalSum = 0;
        for(uint i=0; i <= _n; i++) {
            totalSum = i + totalSum;
        }
        return totalSum;
    }
} 