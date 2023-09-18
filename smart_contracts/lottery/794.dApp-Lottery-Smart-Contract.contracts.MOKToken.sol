//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MOKToken is ERC20 {
    constructor(uint256 initalSupply) ERC20("MOKToken", "MOK") {
        _mint(msg.sender, initalSupply);
    }
}
