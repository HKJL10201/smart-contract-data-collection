// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UniUsdcLPTokenMock is ERC20 {
    constructor(uint256 initialSupply) public ERC20("Uniswap V2 LP of UNI-USDC", "UNI-V2_UNI_USDC") {
        _mint(msg.sender, initialSupply);
    }
}
