//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Exercise2 {
    //FUNCTION 1
    uint[] myArray;
    function setEvens() external {
        for(uint i=0; i<20; i++) {
            if(i % 2 == 0) {
                myArray.push(i);
            }
        }
    }
    function getEvens() external view returns(uint[] memory) {
        return myArray;
    }


    //THE SAME AS ABOVE, BUT I DONT NEED A SEPARATE VIEW FUNCTION
    function setEvens2() pure external returns(uint[] memory) {
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
    
    //FINDING THE BIG NUMBER IN AN ARRAY
    function findBigNum(uint[] memory a) external pure returns(uint) {
        uint bigNumber;
        for(uint i=0; i<a.length; i++){
            a[i]>= bigNumber ? bigNumber = a[i] : bigNumber;
        }
        return bigNumber;
    }

    //FINDINT THE SUM OF AN ARRAY
    function findSum(uint[] memory a) external pure returns(uint) {
        uint totalNumber;
        for(uint i = 0; i<a.length; i++) {
            totalNumber += a[i];
        }
        return totalNumber;
    }

    //FIND THE INDEX NUMBER OF AN ARRAY ELEMENT
    uint[] myArray2 = [8, 4, 55, 66, 99];
    function findIndex(uint a) external view returns(uint) {
        for(uint i = 0; i< myArray2.length; i++) {
            if(myArray2[i]==a) {
                return i;
            }
        }
        revert("value is not in array");
    }
}