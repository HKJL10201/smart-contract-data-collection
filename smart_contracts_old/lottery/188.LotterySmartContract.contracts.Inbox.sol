// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.25;

//similar to class
contract Inbox {
    //storage variable
    string public message;
    
    
   //constructor function (same name as Contract Inbox).
   // Automatically called when contract is first created
constructor(string initialMessage) public {
    message = initialMessage;
}

function setMessage(string newMessage) public {
    message=newMessage;
}

//view = view only  does not modify data (constant)
//returns 
//function returns is used to specify the type of return value that we can expect to see back from a function. only for View or constant 
//returns is only ever going to be used on functions that are marked as View or constant.

function getMessage() public view returns (string){ 
    return message;
}

}

