//SPDX-Licence-Identifier: MIT

pragma solidity >= 0.8.7;

contract StructArray1 {
    struct Cities {
        string name;
        string country;
        uint id;
    }
    Cities var1 = Cities("Windhoek", "Namibia", 1);
    Cities var2 = Cities("Luanda", "Angola", 2);
    Cities[] myArray;

    function addArray() external {
        myArray.push(var1);
    }
    function addArray2() external {
        myArray = [Cities("Luanda", "Angola", 2)];
    }
    uint myNumber = 5;
    uint[] public myArray2 = [1, 2, 3, myNumber];

    function getArray() external view returns(Cities[] memory) {
        return myArray;
    }
}