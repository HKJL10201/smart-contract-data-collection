pragma solidity ^0.5.2; // version won't suddenly break because they have older 

// contract - identical to class
contract Inbox {
    string public message;
    

    constructor(string memory initialMessage) public {
        message = initialMessage;
    }

    // you cannot modify contract and return a value in the same function
    function setMessage(string memory newMessage) public {
        message = newMessage;
    }

}



