// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Wallet {
    
    mapping(address => uint) Wallets;

    function withdrawMoney(address payable _to, uint _amount) external{
        require(Wallets[msg.sender] >= _amount, "Not enough funds");
        Wallets[msg.sender] -= _amount;
        _to.transfer(_amount);
    }

    function getBalance() external view returns (uint) {
        return Wallets[msg.sender];
    }

    receive() external payable {
        Wallets[msg.sender] += msg.value;
    }

    fallback() external payable {
        
    }

}
