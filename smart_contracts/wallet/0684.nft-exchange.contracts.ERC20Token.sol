// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Example Contract implementing ERC20 for Tests
contract ERC20Token is ERC20 {
    constructor() ERC20("ERC20Token", "20") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        _mint(msg.sender, amount);
    }
}