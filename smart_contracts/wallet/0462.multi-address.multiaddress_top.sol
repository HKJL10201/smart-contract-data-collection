pragma solidity ^0.8.7;

contract Base{
    
    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }
    
    modifier notOwner{
    	require(owner != msg.sender);
    	_;
    }
    
    address owner; //  the owner of the contract 
    
    constructor(){
        owner = msg.sender; //setting the owner of the contract
    }
    
    //this struc defines the business of the owner
    struct Business{
        uint BID;
        string businessName;
        address [] partners;
    }
    
    //this struct defines the transaction
    struct Transaction{
        uint TID;
        uint approvalGot;
        uint approvalRequired;
        address sender;
        address receiver;
        uint amount;
        string status;
    }
}
