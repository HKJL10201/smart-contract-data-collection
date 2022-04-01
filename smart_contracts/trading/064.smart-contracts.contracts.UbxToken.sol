// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./utils/upgradeability/Initializable.sol";
import "./utils/ERC20.sol";
import "./utils/ERC20Pausable.sol";
import "./utils/ERC20Burnable.sol";
import "./utils/Ownable.sol";
import "./utils/reclaim/CanReclaimEther.sol";
import "./utils/reclaim/CanReclaimToken.sol";

/**
 * @title Standard ERC20 token, with burning and pause functionality.
 *
 */
contract UbxToken is
    Initializable,
    Ownable,
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    CanReclaimEther,
    CanReclaimToken
{
    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initialSupply,
        address initialHolder,
        address owner,
        address[] memory pausers
    ) public initializer {
        require(pausers.length > 0, "At least one pauser should be defined");
        ERC20.initialize(name, symbol, decimals);
        Ownable._onInitialize(owner);

        Pausable.initialize(pausers[0]);

        for (uint256 i = 1; i < pausers.length; ++i) {
            _addPauser(pausers[i]);
        }

        // create the tokens
        _mint(initialHolder, initialSupply);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
