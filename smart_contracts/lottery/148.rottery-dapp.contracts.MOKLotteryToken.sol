//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MOKLotteryToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MOK Lottery Token", "MLT") {
      _mint(msg.sender, initialSupply); 
    }

    function getSome() public {
      _mint(msg.sender, 100 ether); 
    }
}
