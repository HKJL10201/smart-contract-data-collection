// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Allowance.sol";

contract SimpleWallet is Allowance {

    event MoneySent(address indexed _recipient, uint _amount);   
    event MoneyReceived(address indexed _from, uint _amount);   

    function withdrawMoney(address payable _to, uint _amount) public ownerOrAllowed(_amount) {
        require( _amount <= address(this).balance, "Not enough liquidity in the system");
        if(!isOwner()){
            reduceAllowance(msg.sender, _amount);
        }
        _to.transfer(_amount);
        emit MoneySent(_to, _amount);
    }

    receive() payable external {
        emit MoneyReceived(msg.sender, msg.value);
    }

    function renounceOwnership() public view override onlyOwner{
        revert ("Can't renounce ownership");
    }

}