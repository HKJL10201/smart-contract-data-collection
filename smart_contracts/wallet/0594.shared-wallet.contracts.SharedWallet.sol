// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import "./AllowedAmounts.sol";

contract SharedWallet is AllowedAmounts {

    event MoneyReceived(address indexed _from, uint _amount);

    event MoneySent(address indexed _to, uint _amount);

    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdraw(address payable _to, uint _amount) public allowedToWithDraw(_amount) {
        require(_amount <= getBalance(), "Not enough funds.");

        if (msg.sender != owner()) {
            reduceAmountToWithdraw(msg.sender, _amount);
        }

        emit MoneySent(_to, _amount);

        _to.transfer(_amount);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Can't renounce ownership.");
    }
}
