
/* Written by Anshuman Misra on Nov 2, 2021.

This is a smart contract that acts as a wallet and stores funds for a user on the ethereum blockchain.
The motive behind this smart contrcat is to protect a user from loss if private key. If the owner loses
their private key, guardian acounts can arrive at consensus to reassign ownership to another account
owned by the same user.

*/

pragma solidity ^0.8.0;

contract wallet{
    
    address private owner; // owner of account
    uint256 private balance; // Balance of Wallet
    address[] private guardians;  // set of guardian acounts
    uint256[] private agreement_array; // vector used to arrive at consensus between guardians for changing the ownership of the wallet
    uint256 private counter;  // keeps track of the number of times a change of ownership has been requested

    event ChangeRequest(uint256 s_no); // Event used to communicate between guardians
    address[] private change_list; // Each time the ownership needs to be changed, a new address is pushed into this list
    
    
    
    constructor(address[] memory listofgaurdians) {
        
        // Deploy Wallet and assign ownership and guardian accounts
        
        require(listofgaurdians.length > 2, "Too few guardians");
        require(listofgaurdians.length < 4, "Too many guardians");
    
        owner = msg.sender;
        
        for(uint256 i = 0; i < listofgaurdians.length; i++)
        {
            guardians.push(listofgaurdians[i]);
            
            agreement_array.push(0);
            
        }
       
       
    }
    
    function ChangeOwnerRequest(address new_owner) public payable returns(bool){
        
        bool flag = false;
        
        for(uint256 i = 0; i < guardians.length; i++){
            
            if(guardians[i] == msg.sender){
                
                
                flag = true;
                
            }
                    
           
        }
        
        
        if(flag == false){
                
                return false;
        }
            
        
        counter = counter + 1;
        
        change_list.push(new_owner);
        
        agreechangeowner();
        
        emit ChangeRequest(counter);
        
        return true;
        
        
    }
    
    
    function agreechangeowner() public payable returns(bool){
        
        if(counter < 1){
            
            return false;
        }
        
        for(uint256 i = 0; i < guardians.length; i++)
        {
            if(guardians[i] ==  msg.sender){
                
                // if counter == agreement_array[i] + 1
                
                agreement_array[i] = agreement_array[i] + 1;
                
            }
        }        
        return true; 
        
    }
    
   
    function changeOwner() public payable returns(bool){
        
        bool flag1 = false;
        bool flag2 = true;
        uint256 consensus_count = 0;
        
        // Check if the request is from a guardian account
        
         for(uint256 i = 0; i < guardians.length; i++)
        {
            if(guardians[i] ==  msg.sender){
                
                flag1 = true;
                break;
                
            }
        } 
        
        // Check if the guardians have arrived at consensus 
        
          for(uint256 i = 0; i < guardians.length; i++)
        {
            if(agreement_array[i] ==  counter){
                
                consensus_count = consensus_count + 1;
                
            }
        } 
        
        if(consensus_count <= guardians.length/2){
            
            flag2 = false;
            
        }
        
        
        if(flag1 == true && flag2 == true){
            
            owner = change_list[counter-1];
            
        }
        
        else{
            
            return false;
            
            
        }
        
        return true;
        
    }   
    
   
    function send_money(address _receiver, uint256 amount) public payable {
        
       // Transfer money from wallet. Only owner can initiate this functionality.
       
       require(msg.sender == owner, "Only owner can access funds!");
       require(balance >= amount,"Not enough funds!");
       
       payable(_receiver).transfer(amount);
       balance -= amount;
        
    }
    
     function get() public payable{ 
         
        // Function to receive funds in the wallet
    
        balance += msg.value;

        
    }
    
    function get_balance() public view returns(uint256){
        
        // getter function for balance.
        
        return balance;
    }
   
   function get_owner() public view returns(address){
       
       // getter function for owner.
       
       return owner;
   }
    
  
   }
