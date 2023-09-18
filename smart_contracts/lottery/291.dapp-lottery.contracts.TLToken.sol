// contracts/TLToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title TLToken
/// @notice Simple ERC20 token used for the lottery contract.
contract TLToken is ERC20 {

    /// @dev Constructor of TLToken.
    /// @param initialSupply : initial supply of the token
    constructor(uint256 initialSupply) ERC20("TLT", "TL") {
        _mint(msg.sender, initialSupply);
    }
}
