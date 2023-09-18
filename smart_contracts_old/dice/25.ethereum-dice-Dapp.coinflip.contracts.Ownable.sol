pragma solidity >= 0.5.0 < 0.7.0;
contract Ownable {
    
   address internal owner; 
   
   modifier ownerOnly(){
       require(msg.sender == owner);
       _;
   }
     
   constructor() public {
       owner = msg.sender;
   }
}