// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract ERC20Contract is ERC20PresetMinterPauser {
    constructor (string memory name, string memory symbol) ERC20PresetMinterPauser(name, symbol) {

    }
}