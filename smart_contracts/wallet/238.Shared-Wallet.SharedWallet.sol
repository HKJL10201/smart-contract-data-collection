//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./Allowance.sol";

contract SharedWallet is Allowance {
    event MoneySent(address indexed beneficiary, uint256 amount);
    event MoneyReceived(address indexed fromAddress, uint256 amount);

    // receive money in smart contract via receive fallback
    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }

    // withdraw money from the smart contract to an address for a specified amount, should be accessed only by owner or authorized user
    function withdrawMoney(address payable toAddress, uint256 amount)
        public
        owenerOrAllowedUser(amount)
    {
        // check if there's enough fund in smart contract account's address
        require(
            amount <= address(this).balance,
            "Contract account doesn't have enough balance to process this withdrawal request"
        );
        // if it's not the owner, deduct the allowance
        if (!isOwner()) {
            reduceAllowance(msg.sender, amount);
        }
        emit MoneySent(toAddress, amount);
        toAddress.transfer(amount);
    }
}
