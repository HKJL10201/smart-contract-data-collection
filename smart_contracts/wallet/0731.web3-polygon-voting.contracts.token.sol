// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MagicTestToken is ERC20 {
    constructor() ERC20("Magic Test Token", "MTT") {}

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}