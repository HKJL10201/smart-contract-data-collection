// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DemoUSD is ERC20 {
    constructor(uint256 initialBalance) ERC20("Basic", "DemoUSD") {
        _mint(msg.sender, initialBalance);
    }
}