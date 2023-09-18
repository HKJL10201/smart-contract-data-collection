pragma solidity ^0.8.7;

contract Wallet{
    address payable public owner;

    constructor(){
        owner = payable(msg.sender);
    }

    // принимаем деньги в контракт. Депозит с одного кошелька/смарт-контракта в наш. 
    receive() external payable{}

    function withdraw(uint _amount){
        require(msg.sender == owner, 'You are NOT owner');
        payable(msg.sender).transfer(_amount)
    }

    function getBalance() external view returns(uint){
        return address(this).balance;
    }

}