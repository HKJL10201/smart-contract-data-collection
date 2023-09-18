// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ElectionToken is ERC20 {
    // wei
    constructor(uint256 initialSupply) public ERC20("ElectionToken", "ET") {
        _mint(msg.sender, initialSupply);
    }
}
