pragma solidity >=0.8.7;

contract arrayContract {

    bytes32[] myArray;


    function setValues() external {
        myArray = [bytes32("flower"), bytes32("rose")];
    }

    function addValue() external {
        myArray.push(bytes32("tulip"));
    }

    function getValues() external view returns(bytes32[] memory) {
        return  myArray;
    }


}