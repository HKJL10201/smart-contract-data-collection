//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import'./Allowance.sol';

contract SharedWallet is Allowance {

    event MoneySent(address indexed _toWhom,uint _amount);
    event MoneyReceived(address indexed _byWhom,uint _amount);

    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }
    function withdrawMoney(address payable _to,uint _amount)  OwnerOrAllowed(_amount ) public amountCheck(_amount){  
        _to.transfer(_amount);
        emit MoneySent(_to, _amount);
        if(!isOwner()){
            reduceAllowance(msg.sender,_amount);
        }
        
    }
    
}