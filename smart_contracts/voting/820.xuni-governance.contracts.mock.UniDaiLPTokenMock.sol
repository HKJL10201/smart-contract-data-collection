// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UniDaiLPTokenMock is ERC20 {
    constructor(uint256 initialSupply) public ERC20("Uniswap V2 LP of UNI-DAI", "UNI-V2_UNI_DAI") {
        _mint(msg.sender, initialSupply);
    }
}
