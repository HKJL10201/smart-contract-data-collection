// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract THVToken is Context, ERC20 {

    constructor () ERC20("THVToken", "THV") {
        _mint(_msgSender(), 10000 * (10 ** 18));
    }

    function setApproval(address owner, address spender, uint256 amount) external {
        _approve(owner, spender, amount);
    }
}