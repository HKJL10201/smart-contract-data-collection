pragma solidity ^0.8.7;

contract FunctionOne {
    function getEvens() pure external returns(uint[] memory) {
        uint[] memory evens = new uint[](20);
        uint myIndex = 0;
        for(uint i=1; i<=20; i++) {
            if(i % 2 == 0) {
                evens[myIndex] = i;
                myIndex++;
            }
        }
        return evens; 
    }
} 