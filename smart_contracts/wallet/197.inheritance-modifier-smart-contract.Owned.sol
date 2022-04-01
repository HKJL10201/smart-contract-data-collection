pragma solidity ^0.5.13;

contract Owned {
    
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier isOwner {
        require(msg.sender == owner, "Only owner is allowed to do this operation!");
        _;
    }
    
}