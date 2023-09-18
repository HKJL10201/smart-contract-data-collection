// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SharedWallet.sol";

contract Wallet is SharedWallet {

    event MoneyWithdraw(address indexed _to, uint _amount);
    event MoneyRecived(address indexed _from, uint _amount);

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoney(uint _amount) external ownerOrWithinLimits(_amount){
        require(_amount <= getBalance(), "Not enought funts!");

            if(!isOwner()) {deduceFromLimit(msg.sender, _amount);}

        payable(msg.sender).transfer(_amount);

        emit MoneyWithdraw(msg.sender, _amount);
    }

    fallback() external payable {}
    receive() external payable {
        emit MoneyRecived(msg.sender, msg.value);
    }
}