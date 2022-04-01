// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./Allowance.sol";

contract Wallet is Allowance {
    event MoneySent(address indexed _beneficiary, uint _amount);
    event MoneyReceived(address indexed _from, uint _amount);

    function withdraw(address payable _to, uint _amount) public ownerOrAllowed(_amount) {
        require(_amount <= getBalance(), "not enough founds");

        if(!isOwner()) {
            reduceAllowance(msg.sender, _amount);
        }
        
        _to.transfer(_amount);

        emit MoneySent(_to, _amount);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function renounceOwnership() override pure public {
        revert("Can't renounce ownership");
    }

    receive () external payable  {
        emit MoneyReceived(msg.sender, msg.value);
    }
}
