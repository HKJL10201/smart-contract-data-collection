pragma solidity ^0.4.0;

contract BankAccount {
    uint public number = 34;
    address public contractCreator;
    
    function BankAccount(){
        contractCreator = msg.sender;
        /* We can think of the msg value as a context value at runtime. 
        If you are a sender, who sent this contract?
        msg somehow holds its address (this.)
        
        */
    }
    
    /*Something extra for the security changes we made to the setNumber function. 
    You may receive an error the first time it is written */
    modifier canChangeValue(){
        if(contractCreator != msg.sender){
            throw;
        }
        _;
    }
    
     function getNumber() constant returns (uint) {
         number = 55;
        return number;
    }
    
    function setNumber(uint newValue) canChangeValue returns(uint) {
        /*if(contractCreator != msg.sender){
        //    return 0;
        } We did a security thing here just to do the digit change ourselves. */
        number = newValue;
        return number;
    }
}