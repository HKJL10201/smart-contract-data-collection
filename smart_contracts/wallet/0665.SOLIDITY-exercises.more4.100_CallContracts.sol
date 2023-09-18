//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Caller {
    //EXAMPLE 1 : two different ways of same thing
    /*Receiver: is the contract name below
    otherContract: address of the contract below
    anyNumber: any number we want 
    setNumber: the function that we call
    After this, myNumber value will update.*/
    function callFn1a(address otherContract, uint anyNumber) external {
        Receiver(otherContract).setNumber(anyNumber);
    }
    function callFn1b(Receiver otherContract, uint anyNumber) external {
        otherContract.setNumber(anyNumber);
    }

    //EXAMPLE 2:
    //Function 2a will work but will not return anything on the interaction area. To return sth use 2b
    function callFn2a(Receiver otherContract) external view {
        otherContract.getNumber();
    }
    function callFn2b(Receiver otherContract) external view returns(uint) {
        uint x = otherContract.getNumber();
        return x;
    }
    function callFn2c(Receiver otherContract) external view returns(uint x) {
        x = otherContract.getNumber();
    }

    //EXAMPLE 3: 
    //To call a "payable" function, our caller should also be "payable"
    function callFn3(Receiver otherContract, uint n) external payable {
        otherContract.sendEther{value: msg.value}(n);
    }

    //EXAMPLE 4:
    //This function will call another contract function which returns multiple values.
    //The important point here is to see how you can save and return multiple values. You need to use parentheses.
    function callFn4a(Receiver otherContract) external view returns(uint, uint) {
        (uint x, uint y) = otherContract.getValues();
        return(x,y);
    }
    function callFn4b(Receiver otherContract) external view returns(uint x, uint y) {
        (x,y) = otherContract.getValues();
    }
}


contract Receiver {
    //EXAMPLE 1
    uint public myNumber;
    function setNumber(uint _n) external {
        myNumber = _n;
    }

    //EXAMPLE 2
    function getNumber() external view returns(uint) {
        return myNumber;
    }

    //EXAMPLE 3
    uint public myNumber2;
    uint public value;
    function sendEther(uint n) external payable {
        myNumber2 = n; // There is no need this line.And there is no need for parameter "n".
        value = msg.value; // There is no need this line.
    }
    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    //EXAMPLE 4
    uint myNum1 = 25;
    uint myNum2 = 55;
    function getValues() external view returns(uint, uint) {
        return(myNum1, myNum2);
    }
}