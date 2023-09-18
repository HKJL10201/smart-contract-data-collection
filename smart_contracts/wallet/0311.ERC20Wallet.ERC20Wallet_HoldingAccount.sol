// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ERC20Wallet {
    address payable public owner; 

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {
    }

    function withdraw(uint256 _amount, IERC20 token) public {
        require(msg.sender == owner, "caller is not owner");
        require(_amount <= token.balanceOf(address(this)), "Balance too small to withdraw this amount");

        token.transfer(owner, _amount);
    }

    function getBalance(IERC20 token) external view returns (uint) {
        return token.balanceOf(address(this));
    }
}


contract ERC20HoldingAccount {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable{

    }

    function sendERC20(uint256 _amount, address recipient, IERC20 token) public {
        require(msg.sender == owner, "caller is not owner");
        require(_amount <= token.balanceOf(address(this)), "Balance too small to withdraw this amount");

        token.transfer(recipient, _amount);
    }

    function getBalance(IERC20 token) external view returns (uint) {
        return token.balanceOf(address(this));
    }
}