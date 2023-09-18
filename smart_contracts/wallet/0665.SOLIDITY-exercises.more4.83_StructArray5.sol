//SPDX-Licence-Identifier: MIT

pragma solidity 0.8.7;

contract Struct5 {

    //1.FOUNDATION SETUP
    struct Cars {
        string brand;
        uint price;
        string color;
    }

    Cars myCar1 = Cars("BMW", 7000, "blue");
    Cars myCar2 = Cars("Ford", 15750, "black");

    //2) STRUCT VAR. ARRAY OPERATIONS
    // myArray.push(myCar2); this line outside the function 
    // will not work and give error. You must place it inside the function. 
    Cars[] myArray;
    function addArray() external {
        myArray.push(myCar1);
        myArray.push(myCar2);
    }

    // DELETE 1
    function deleteVar1() external {
        delete myArray[0].brand;
    }

    // DELETE 2
    function deleteVar2() external {
        delete myCar1;
    }

    // DELETE 3
    function deleteVar3() external {
        delete myArray;
    }

    // GET: return a struct variable which is in storage(state variable)
    function getCars() external view returns(Cars memory){
        return myCar1;
    }
    // GET: return a struct variable array
    function getArray() external view returns(Cars[] memory){
        return myArray;
    }
}