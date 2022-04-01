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

    // CREATE: create a new struct variable by using the array
    // We must declare the new struct as "storage" or "memory".
    // This function will change array[0] brand as "nonsense brand"
    function newStruct() external {
        Cars storage myNewCar = myArray[0];
        myNewCar.brand = "NONSENSE BRAND";
    }

    // This function will change array[0] brand as "nonsense brand"
    // And it will also add new struct to array. So, array[0] and array[2] 
    // will be the same
    function newStruct2() external {
        Cars storage myNewCar2 = myArray[0];
        myNewCar2.color = "NONSENSE COLOR";
        myArray.push(myNewCar2);
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