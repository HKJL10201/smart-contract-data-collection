//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract EnumTest2 {
    //Enums are generally used enrich a struct. Imagine we have a bool in a struct
    // and it true or false. What if we want it to be "pending, confirmed, paid, cancelled,...."
    // for this purposes we can use enums.

    //Creating enums are similar to struct(without semicolon). After creating it, we can also 
    // create enum variables from it. 
    enum Status {
        Schwanow,
        Pending,
        Shipped,
        Completed,
        Rejected,
        Cancelled
    }
    Status myStatus; //default value for myStatus is 0 which is representing "none".

    // SET/UPDATE ENUM:
    function setEnum() external {
        myStatus = Status.Completed;
    }

    // RETURN ENUM VARIABLE
    //This will return the index value of myStatus. "Completed" is not in the third index.
    // so result will be 3. But 3 here is not a uint, it is a enum index.
    // Default value for enum variables is 0.
    function getEnum() external view returns(Status) {
        return myStatus;
    }

    // SET ENUM VALUE DYNAMICALLY:
    // Status is our enum name, and x will be a uint8 index number. You can then set 
    // any enum index number to our previously declared enum variable.
    function setEnum2(Status x) external {
        myStatus = x;
    }

    //DELETE
    //this will reset the value of enum variable to its default value which is 0
    function resetEnum() external {
        delete myStatus;
    }
}