//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

library Goodmath {
    function compareNum(int a, int b) internal pure returns(int) {
        return a >= b ? a : b;
    }

    function addNum(int a, int b) internal pure returns(int) {
        return a+b;
    }

    function findBigNum(uint[] memory a) internal pure returns(uint) {
        uint bigNumber;
        for(uint i=0; i<a.length; i++){
            a[i]>= bigNumber ? bigNumber = a[i] : bigNumber;
        }
        return bigNumber;
    }

    function findLength(string memory str) internal pure returns (uint) {
        return bytes(str).length;
    }

    function findSum(uint[] memory a) internal pure returns(uint) {
        uint totalNumber;
        for(uint i = 0; i<a.length; i++) {
            totalNumber += a[i];
        }
        return totalNumber;
    }

    function findIndex(uint[] storage myArray, uint a) internal view returns(uint) {
        for(uint i = 0; i< myArray.length; i++) {
            if(myArray[i]==a) {
                return i;
            }
        }
        revert("value is not in array");
    }
}

contract LibraryTest {
    function compareNumbers(int a, int b) external pure returns(int) {
        return Goodmath.compareNum(a, b);
    }
    function addNumbers(int a, int b) external pure returns(int) {
        return Goodmath.addNum(a, b);
    }
    function findBigNumber(uint[] memory a) external pure returns(uint){
        return Goodmath.findBigNum(a);
    }
    function findStringLength(string memory a) external pure returns(uint){
        return Goodmath.findLength(a);
    }
    function findTotal(uint[] memory a) external pure returns(uint){
        return Goodmath.findSum(a);
    }

    //ALTERNATIVE: using Goodmath for uint[];
    uint[] myArray = [8, 95, 44, 88, 77, 66, 22, 33, 11, 98, 99, 90, 93, 91, 97, 96, 94, 92, 90];
    function findIndex(uint a) external view returns(uint){
        return Goodmath.findIndex(myArray, a);
        //ALTERNATIVE: return myArray.findIndex(a);
    }
}


/* To create your own library:
RULE: You cannot declare state variables inside library
RULE: Library functions are either pure(if they read only their parameters) or 
view (if they read from storage variables).

RULE: make sure functions you declare are "internal"
--You dont need "external", because you this function doesnt have any use on its own.
It is a part of other functions. 
--You also dont need "private", because if you say private, you cant use it with other functions.
It will mean this function will only be accessible to library. But we want to use in other contracts.
--Also you dont need "public". If you say public, the library would need to deployed separetely and this means 
it will used on its own. The same reason of rejection as "external".
 */