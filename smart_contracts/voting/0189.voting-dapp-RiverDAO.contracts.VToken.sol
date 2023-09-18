// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VToken is ERC20 {
    
    constructor() ERC20("VToken", "VTK") {
        _mint(msg.sender, 10100000 * 10 ** decimals());
    }
}

/*
@DEV Total supply of token will put into a crowdsale so will be available
for anyone to buy at the beginning at a lower price and then will be when
all the rest will be available in a DEX for anyone to buy it.

10000000 VTK will be in available in the crowsale. If all the token are sold there are 100000 VTK
more to send into a DEX and then it will be traded publicly for anyone.
*/