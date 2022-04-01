pragma solidity >=0.8.7;

contract arrayContract {

    uint[] myArray;

    function setArray() public {
        myArray = [24, 55, 66];
    }
    function addArray(uint _number) external {
        myArray.push(_number);
    }
    function getArray() external view returns(uint[] memory) {
        return myArray;
    }
}