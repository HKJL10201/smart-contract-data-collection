// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract OPTToken is ERC20 {
    constructor(uint256 initSupply) ERC20("OPT Token","OPP"){
        _mint(msg.sender, initSupply);
    }
}