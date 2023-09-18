// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';

contract GovernanceToken is ERC20Votes {

    /// @dev Sets ERC20Votes total supply through ERC20Votes mint function, 
    /// total supply will be assigned to contract owner
    constructor(
        string memory name,
        string memory symbol, 
        uint256 totalSupply
        )
        ERC20(name, symbol)
        ERC20Permit(name)
    {
        _mint(msg.sender, totalSupply);
    }
}
