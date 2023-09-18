// SPDX-License-Identifier: GPL-3.0

//Objective:
//Anyone can send Ethers
//Only owner can withdraw
//Anyone can check wallet balance

pragma solidity >=0.7.0 <0.9.0;

contract simpleWallet{

//Define owner as state variable
address payable public owner;

//The one ho calls the contract for the first time is the owner 
constructor()
{owner = payable(msg.sender);}

//Payable function returns nothing (setter function only takes ethers as an argument and stores ethers inside the smart contract)
//Since we need ethers to store inside of our wallet (smart contract) 
function getEthToWallet() payable external{}
//We could also use
//receive() payable external{}

//Verify Owner or Not
modifier verifyOwner{
    require(msg.sender==owner,"Only restricted to Wallet Owner");
    _;
}

//Transfer the amount from caller's account to this wallet (smart contract)
function withdraw(uint _amount) external verifyOwner{
payable(msg.sender).transfer(_amount);
}

//To know the wallet balance
function getWalletBalance() external view returns (uint){
return address(this).balance;
}

//To know the owner balance
function getOwnerBalance() external view returns (uint){
return address(owner).balance;
}


}