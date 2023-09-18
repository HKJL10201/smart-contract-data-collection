// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FT is ERC20 {


    address payable owner; // TODO: check state visibility

    constructor(uint256 initialSupply) ERC20("Auction Token", "ATN") {

        owner = payable(msg.sender);
        _mint(owner, initialSupply);
    }




}