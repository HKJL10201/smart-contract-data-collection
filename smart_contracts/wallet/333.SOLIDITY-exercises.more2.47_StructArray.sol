//SPDX-Licence-Identifier

pragma solidity >=0.8.7;

contract StructArray {

    struct Flowers {
        string name;
        string color;
    }
    Flowers flower;
    Flowers flower2;

    function setValue() external {
        flower = Flowers("rose", "white");
        flower2 = Flowers("tulip", "blue");
    }

    //Create a struct variables array and add struct variables to it.
    Flowers[] myArray;
    function addArray() external {
        myArray.push(flower);
        myArray.push(flower2);
    }

    //Return the whole struct variable array
    function getArray() external view returns(Flowers[] memory) {
        return myArray;
    }

    //Return the individual values of the struct variable
    function getName() external view returns(string memory) {
        return flower.name;
    }

    //Return the whole struct variable
    function getColor() external view returns(Flowers memory) {
        return flower;
    }

}