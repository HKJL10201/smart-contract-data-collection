// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract Adoption {
    //Solidity has a unique type called an address. Addresses are Ethereum addresses, stored as 20 byte values. 
    //Every account and smart contract on the Ethereum blockchain has an address and can send and receive Ether 
    //to and from this address. The address length is going to be set to 16 characters i.e. x0^14
    address[16] public adopters;

    // Function to allow adopter to adopt a pet. Get PetID from a public getter request
    function adopt(uint petId) public returns (uint) {
    
        //We are checking to make sure petId is in range of our adopters array, we have 15 pets that need adopting
        require(petId >= 0 && petId <= 15);
        
        //The address of the person or smart contract who called this function is denoted by msg.sender
        adopters[petId] = msg.sender;

        //Get return of petID from web shop that was adopted in the code above when ownership of the pet was transfered to the adopters wallet
        return petId;
    }

    // Retrieving the adopters in an array instead of 1 by 1
    function getAdopters() public view returns (address[16] memory) {
        return adopters;
    }

}