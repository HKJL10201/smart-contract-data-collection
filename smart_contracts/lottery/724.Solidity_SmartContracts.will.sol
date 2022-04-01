// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Will {
    address owner;
    uint amount;
    bool isDeceased;
    
    constructor() payable {  //payable represents ether transfer involed in this call
        owner = msg.sender; // msg represents the call from ethereum, and sender represents who is called this method
        amount = msg.value; // how much ether is being sent 
        isDeceased = false; // we assume the actual persion is setting up the will h
        
    }
    
    //create modifier so that only persion who call this contract is owner
    modifier onlyOwner {
        require(msg.sender == owner); //here msg.sender is who called this method and owner is already saved in constructor
        _; // if above condition true then just continue otherwise not
    }
    
    // create modifier to allocate funds only when owner is deceased
    modifier mustbeDeceased {
        require (isDeceased == true);
        _;
    }
    
    // define familywallets 
    address payable[] familywallets;
    
    // helps to store keys and values respectively
    mapping(address => uint) inheritance;
    
    //set inheritance for each address, basically the owner storing how much amount each family memeber should get it,
    // hence owner need to setup list of beneficiaries's address and amount
    //
    function setInheritance(address payable wallet, uint amount) public onlyOwner {
        familywallets.push(wallet); // list of family address
        inheritance[wallet] = amount; // mapping of each family memeber amount, i.e. storing the amount which will transfer to respective address after owner deased
    }
        
    //pay each family memeber based on their wallet address
    
    function payout() private mustbeDeceased { 
        // checking whether the owner is deased or not with the help of modifiers, if true then only it will continue
        
        for(uint i=0; i< familywallets.length; i++) {
            familywallets[i].transfer(inheritance[familywallets[i]]); // here actual tranfer will made with 'transfer' keyword to receiver address from storage of contract 
            
        }
    }
    
    //orcale switch simulation
    function deceased() public onlyOwner {
        isDeceased = true;
        payout();
    }
    
    
}