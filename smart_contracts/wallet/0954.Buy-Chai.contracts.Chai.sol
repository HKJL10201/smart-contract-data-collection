// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

// Define a contract named "chai"
contract chai {
    // Define a struct named "Memo" to store memo details
    struct Memo {
        string name;
        string message;
        uint256 timestamp;
        address from;
    }

    // Declare an array of Memo structs to store all memos
    Memo[] memos;
    //array type [] name of array;

    // Declare a payable address variable named "owner" to store the contract owner's address
    address payable owner;

    // Constructor function to initialize the contract owner's address
    constructor() {
        owner = payable(msg.sender);
         // by "msg.sender" we get the address of account that deployed the contract
         //so owner is by whom the contract is deployed 
    }

    // Function to buy a chai and leave a memo
    function buyChai(string memory name, string memory message) public payable {
        //we have to use memory with string if we have to use string in function because by default string are not stored in stack
        
        // Require the caller to send a non-zero amount of ether
        require(msg.value > 0, "Please pay greater than 0 ether");
        //first it check require statement which is >0 if it is false then it stop
        //executition and return error message which is defined
        //here by msg.value the buyer will declared, who call the function will became the buyer

        // Transfer the ether sent by the caller to the contract owner's address
        owner.transfer(msg.value);
        // Add a new Memo struct to the "memos" array with the provided name, message, timestamp, and caller's address
        memos.push(Memo(name, message, block.timestamp, msg.sender));
    }

    // Function to get all memos
    function getMemos() public view returns (Memo[] memory) {
        // Return the entire "memos" array
        return memos;
    }
}
