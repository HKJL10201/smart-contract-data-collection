//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./SmartWallet.sol";

contract SmartWalletFactory {
    address[] public wallets;

    function deployWallet() external {
        address newWallet = address(new SmartWallet(payable(msg.sender)));
        wallets.push(newWallet);
    }
}