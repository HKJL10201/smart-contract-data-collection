//SPDX-Licence-Identifier: MIT

pragma solidity 0.8.7;

contract Struct5 {
    struct Cars {
        string brand;
        uint price;
        string color;
    }

    Cars myCar1 = Cars("BMW", 7000, "blue");
    Cars myCar2 = Cars("BMW", 15750, "black");

    function changeCarProperties(string memory _color) external {
        myCar1.color = _color;
    }
    // other ways to create a struct variable:
    function createStructVar() external {
        Cars memory myCar3 = Cars("Toyota", 6300, "hay");
        Cars memory myCar4 = Cars({price: 5000, color: "maze", brand:"mustang"}); //order doesnt matter in this way
        Cars memory myCar5; // car values will have default values: "", 0, ""
        Cars memory myCar5
    }

    function getCars() external view returns(Cars memory){
        return myCar1;
    }
}