pragma solidity ^0.5.17;


contract Mortal {
    
    /* Define variable owner of the type address */
    address payable owner;

    /* This function is executed at initialization and sets the owner of the contract */
    constructor() public { owner = msg.sender; }

    /* Function to recover the funds on the contract */
    function kill() public returns(string memory){ 
        if (msg.sender == owner) 
            selfdestruct(owner); 
        return "Bye";
    }
}

contract Greeter is Mortal {
    
    /* Define variable greeting of the type string */
    string greeting;

    /* This runs when the contract is executed */
    constructor(string memory _greeting) public {
        greeting = _greeting;
    }

    /* Main function */
    function greet() view external returns (string memory) {
        return greeting;
    }
}