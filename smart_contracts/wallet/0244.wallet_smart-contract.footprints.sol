// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract donate{
    function receiveMoney() public payable{

    }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function transferMoney(address payable account, uint amount) public{
        account.transfer(amount);

    }
} 