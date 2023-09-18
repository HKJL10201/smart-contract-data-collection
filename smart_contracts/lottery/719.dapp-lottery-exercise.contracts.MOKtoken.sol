// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//0x35a8e0A45ae3bdaEc3D43F8912d910f0d49AE2F7
contract MOKToken is ERC20 {
    constructor() ERC20("MOKToken", "MOK") {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }
} 