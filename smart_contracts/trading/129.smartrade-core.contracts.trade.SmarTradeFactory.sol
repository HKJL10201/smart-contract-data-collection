// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/ISmarTradeRegistry.sol";
import "../interfaces/ISmarTrade.sol";

/**
 * @dev {SmarTradeFactory}
 */
contract SmarTradeFactory is Context, AccessControl {
    using SafeMath for uint256;
    using Address for address;

    bytes32 public constant SUPER_ROLE = keccak256("SUPER_ROLE");

    // Registry
    address private _registry;

    /**
     * @dev Emitted when a `creator` created a new trade (`newTrade`).
     */
    event TradeCreated(address indexed creator, address indexed newTrade);

    /**
     * @dev Emitted when a `setter` changed a `registry`.
     */
    event RegistryChanged(address indexed setter, address indexed registry);

    /**
     * @dev Initializes the contract by setting `registryAddress`.
     */
    constructor(address registryAddress) public {
        require(
            registryAddress != address(0),
            "SmarTradeFactory: cannot be the zero address"
        );

        require(
            registryAddress.isContract(),
            "SmarTradeFactory: must be contract"
        );

        _registry = registryAddress;

        // Sets super role
        _setupRole(SUPER_ROLE, _msgSender());
    }

    /**
     * @dev Returns registry address.
     */
    function getRegistryAddress() public view returns (address) {
        return _registry;
    }

    /**
     * @dev Allows for super role to set the desired registry for contract creation.
     *
     * Requirements:
     *
     * - the caller must have super role (`SUPER_ROLE`).
     * - `registryAddress` must not be the zero address.
     * - `registryAddress` must be contract.
     */
    function setRegistryAddress(address registryAddress) public virtual {
        require(
            hasRole(SUPER_ROLE, _msgSender()),
            "SmarTradeFactory: must have super role"
        );

        require(
            registryAddress != address(0),
            "SmarTradeFactory: cannot be the zero address"
        );

        require(
            registryAddress.isContract(),
            "SmarTradeFactory: must be contract"
        );

        _registry = registryAddress;

        emit RegistryChanged(_msgSender(), _registry);
    }

    /**
     * @dev Deploys a new instance of a trade contract and adds it to the whitelist.
     */
    function deploySmarTrade(address newTrade, address parentTrade) public virtual {
        deployVotingSmarTrade(newTrade, parentTrade, address(0), 0);
    }

    /**
     * @dev Deploys a new instance of a voting trade contract and adds it
     *  to the whitelist.
     *
     * Requirements:
     *
     * - the caller must have the `SUPER_ROLE`.
     * - can only create child trade when matched condition.
     */
    function deployVotingSmarTrade(
        address newTrade,          // New trade
        address parentTrade,
        address poll,              // Create poll
        uint256 nextTradeProposal
    )
        public
        virtual
    {
        require(
            hasRole(SUPER_ROLE, _msgSender()),
            "SmarTradeFactory: must have super role"
        );

        require(
            (parentTrade == address(0)) || (parentTrade != address(0) && _canCreateChildTrade(parentTrade)),
            "SmarTradeFactory: cannot create child trade"
        );

        emit TradeCreated(_msgSender(), newTrade);

        if (parentTrade != address(0)) {
            // Set child trade
            ISmarTrade(parentTrade).setChildTrade(newTrade);
        } else {
            // Add to white list
            ISmarTradeRegistry(_registry).addContractToWhiteList(newTrade);
        }

        if (poll != address(0)) {
            ISmarTrade(newTrade).createPoll(poll, nextTradeProposal);
        }
    }

    /**
     * @dev Checks if user can create child trade.
     */
    function _canCreateChildTrade(address parentTrade) internal view returns (bool) {
        bool canCreate = ISmarTrade(parentTrade).canCreateNextTrade();
        return canCreate;
    }
}
