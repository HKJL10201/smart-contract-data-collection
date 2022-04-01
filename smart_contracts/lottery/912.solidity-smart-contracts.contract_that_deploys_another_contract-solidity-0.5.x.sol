pragma solidity ^0.5.2;

contract A{
    address public ownerA;
    constructor(address _eoa) public{
        ownerA = _eoa;
    }
    
}


contract Creator{
    address public ownerCreator;

    //in solidity 0.5.x a Type contract is not implicitly  convertible to Type address 
    A[] public deployedA;
    
    //address[] public deployedA;  //in solidity 0.4.x

    
    constructor() public{
        ownerCreator = msg.sender;
    }
    
    
    function deployA() public{
        
       //in solidity 0.5.x a Type contract is not implicitly  convertible to Type address 
        A new_A_address = new A(msg.sender);
        
        //address  new_A_address = new A(msg.sender);  //in solidity 0.4.x
        
        deployedA.push(new_A_address);
    }
    
}
