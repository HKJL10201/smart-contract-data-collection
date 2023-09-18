//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Controlable
 */

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

contract Controlable is AccessControlUpgradeable {
    IERC20Upgradeable token;
    mapping(address => bool) validNfts;

    function __Controlable_init(IERC20Upgradeable tokenContract_) internal onlyInitializing {
        __Controlable_initunchained(tokenContract_);
    }

    function __Controlable_initunchained(IERC20Upgradeable tokenContract_) internal onlyInitializing {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        token = tokenContract_;
    }

    function setToken(
        IERC20Upgradeable tokenContract_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token = tokenContract_;
    }

    function setNftContract(
        address nftContract_,
        bool isAccepted_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validNfts[nftContract_] = isAccepted_;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}