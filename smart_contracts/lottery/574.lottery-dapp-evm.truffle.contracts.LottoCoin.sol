// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract LottoCoin is
    ERC20,
    // ERC20Burnable,
    ERC20Permit,
    // ERC20Votes,
    Ownable
{
    constructor(
        uint256 initialSupply_,
        string memory tokenName_,
        string memory tokenSymbol_
    ) ERC20(tokenName_, tokenSymbol_) ERC20Permit(tokenName_) {
        _mint(msg.sender, initialSupply_ * (10**18));
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function mintMinerReward() public {
        _mint(block.coinbase, 1000);
    }
}
