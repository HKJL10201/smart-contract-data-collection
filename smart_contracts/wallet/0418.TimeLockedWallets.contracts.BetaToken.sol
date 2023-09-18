// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Our ERC20 token for test purposes.
contract BetaToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Beta", "BT") {
        _mint(msg.sender, initialSupply);
    }
}
