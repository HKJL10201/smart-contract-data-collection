// SPDX-License-Identifier: MIT.
pragma solidity ^0.8.7;

// #region Imports

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

// #endregion

contract MyCoin is ERC20 {

    // #region Constructor

    /// Sets the values for {name}, {symbol} and mint with {initialSupply}.
    /// 
    /// The default value of {decimals} is 18. To select a different value for 
    /// {decimals} you should overload it.
    /// 
    /// All two of these values are immutable: they can only be set once during
    /// construction.
    /// 
    /// @param name_ The name of the token (e.g. "Ether").
    /// @param symbol_ The symbol of the token (e.g. "ETH").
    /// @param initialSupply The initial suply including decimals (e.g. 21000000000000000000000000).
    constructor(string memory name_, string memory symbol_, uint256 initialSupply) ERC20(name_, symbol_) {
        _mint(msg.sender, initialSupply);
    }

    // #endregion
}
