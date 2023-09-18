// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Wallet{
    address payable public owner;

    event Withdrawal(address indexed _to, uint _value);

    constructor(){
        //Set the deployer as the contract's owner
        owner = payable(msg.sender);
    }

    modifier onlyOwner{
        require(msg.sender == owner, "Only owner can perform this action!");
        _;
    }

    receive() external payable{}

    fallback() external payable{}

    function withdraw(uint _amount) public onlyOwner{
        require(_amount > 0 && address(this).balance >= _amount, "Invalid amount!");
        payable(msg.sender).transfer(_amount);
        emit Withdrawal(owner, _amount);
    }

    function send(address payable _to, uint _amount) public payable onlyOwner(){
        _to.transfer(_amount);
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

}
