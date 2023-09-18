// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../openzeppelin-solidity/contracts/ERC20/ERC20.sol";

contract TestTokenERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        _mint(msg.sender, 1_000_000_000e18);
    }
}