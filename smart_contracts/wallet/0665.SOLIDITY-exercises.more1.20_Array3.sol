pragma solidity >=0.8.7;

contract arrayContract {

    uint[] myArray;

    function setArray() public returns(uint[] memory) {
        myArray = [24, 55, 66];
        return myArray;
    }
}