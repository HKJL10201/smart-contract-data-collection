// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
contract Token is ERC20PresetFixedSupply{
    constructor()
    ERC20PresetFixedSupply(
        "Token",
        "TKN",
        3000000000000000000000000,
        msg.sender
    )
    {}
}
