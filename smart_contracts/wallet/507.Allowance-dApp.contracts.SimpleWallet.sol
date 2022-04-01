// SPDX-License-Identifier: MIT

pragma solidity ^0.5.13;

import "./Allownace.sol";

contract SimpleWallet is Allowance {
    
    event MoneySent(address indexed _benificiary, uint _amount);
    event MoneyReceived(address indexed _from, uint _amount);

    function withdrawMoney(address payable _to, uint _amount) public ownerOrAllowed(_amount) {
        require(_amount <= address(this).balance, "There are not enough funds stored in the smart contract");
        if (msg.sender != owner) {
            reduceAllownace(msg.sender, _amount);
        }
        emit MoneySent(_to, _amount);
        _to.transfer(_amount);
    }
    
    function () external payable {
        // fallback function replaced with fallback () or receive () in future versions
        emit MoneyReceived(msg.sender, msg.value);
        
    }
    
}
