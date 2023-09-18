//SPDX-Licence-Identifier: MIT

pragma solidity >=0.8.7;

contract MappingExercise {

    mapping(uint => string) public myWords;
    function addMapping(uint a, string memory b) external {
        myWords[a] = b;
    } 
    

    uint[] public myArray;
    function addArray(uint c) external {
        myArray.push(c);
    }




    function getArray() external view returns(uint[] memory) {
        return myArray;
    }
    function getMapping(uint key) external view returns(string memory) {
        return myWords[key];
    }

}