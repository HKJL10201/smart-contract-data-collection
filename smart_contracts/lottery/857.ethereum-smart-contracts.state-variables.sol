//License
//SPDX-License-Identifier: GPL-3.0

//compiler version
pragma solidity 0.8.0;

//define the contract
contract StateVariables{

    //variable
    int public price;
    string public location;
    //immutable variables don't need to be initialised as soon as they are declared
    //immutable variable cannot change after initialisation
    address immutable public owner;
    //constant variable needs to be initialised as soon as they are declared
    //their value cannot be changed
    int constant area = 100;


    //constructor
    constructor(int _price, string memory _location){

        price = _price;
        location = _location;
        owner = msg.sender;
    }

    //setter function
    function setPrice(int _price) public{

       price = _price;
    }


    //setter function
    function setLocation(string memory _location) public{

        location = _location;
    }



}