pragma solidity ^0.4.0;

contract BankAccount {
    
    address accountOwner;
    bool public transferFlag = false;
    
   function BankAccount(){
       accountOwner = msg.sender;
   }
   
   modifier canWidthDrawMoney() {
       if(msg.sender != accountOwner){
           throw;
       }
       _;
   }
   
   function withdrawMoney(uint amount) canWidthDrawMoney {
       if(accountOwner.send(amount)){
           transferFlag = true;
       }else {
           transferFlag = false;
       }
   }  // Withdrawal process

   function depositMany() payable {
       
   } // Money deposit process (setter)
   
   function checkBalance() constant returns(uint){
       return this.balance;
   } //cashback process ( getter )
    
}