pragma solidity ^0.4.24;

contract A{
    address public ownerA;
    constructor(address _eoa) public{
        ownerA = _eoa;
    }
    
}


contract Creator{
    address public ownerCreator;
    address[] public deployedA;
    
    constructor() public{
        ownerCreator = msg.sender;
    }
    
    function deployA() public{
        address  new_A_address = new A(msg.sender);
        deployedA.push(new_A_address);
    }
    
}