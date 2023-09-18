// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//Declaring a contract Buying_Laptop

contract Buying_Laptop{

    //Now declaring a structure with a name Laptop

    struct Laptop{
        string lap;
        uint256 price;
    }

    //assigning the structure(class) Laptop to the object l1

    Laptop l1;

    //Now using mapping method for mapping address to payment (uint256)

    mapping (address => uint256) public Payforlaptop;

    //Using function for getting input and declaring public
    function Input(string memory LaptopName,uint256 LaptopPrice)public {

        //Now assigning object to the input variable

        l1.lap = LaptopName;
        l1.price = LaptopPrice;

       
    }

    //Using function for diplaying the output and making the visibility view

    

    function Display() public view returns(string memory,uint256){

        return(l1.lap,l1.price);
    }
    //using funtion for making payment by using payable function 
    function Pay()public payable{

         Payforlaptop[msg.sender]+=msg.value;
    }

}

1
