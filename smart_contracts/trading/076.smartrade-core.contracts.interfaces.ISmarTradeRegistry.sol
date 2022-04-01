// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/introspection/IERC165.sol";

/**
 * @dev Required interface of an ISmarTradeRegistry compliant contract.
 */
interface ISmarTradeRegistry is IERC165 {
    /**
     * @dev Emitted when `contractAddress` added to whitelist.
     */
    event ContractAdded(address indexed contractAddress, address indexed creator);

    /**
     * @dev Emitted when `contractAddress` removed from whitelist.
     */
    event ContractRemoved(address indexed contractAddress, address indexed remover);

    /**
     * @dev Emitted when `factoryAddress` added to whitelist.
     */
    event FactoryAdded(address indexed factoryAddress, address indexed creator);

    /**
     * @dev Emitted when `factoryAddress` removed from whitelist.
     */
    event FactoryRemoved(address indexed factoryAddress, address indexed remover);

    /**
     * @dev Returns if contract is whitelisted
     */
    function isContractWhiteListed(address contractAddress) external view returns (bool);

    /**
     * @dev Returns if factory is whitelisted
     */
    function isFactoryWhiteListed(address contractAddress) external view returns (bool);

    /**
     * @dev Adds contract to whitelist
     *
     * Requirements:
     *
     * - `contractAddress` cannot be the zero address.
     * - `contractAddress` must not exists.
     *
     * Emits a {ContractAdded} event.
     */
    function addContractToWhiteList(address contractAddress) external;

    /**
     * @dev Removes contract from whitelist
     *
     * Requirements:
     *
     * - `contractAddress` cannot be the zero address.
     * - `contractAddress` must exists.
     *
     * Emits a {ContractRemoved} event.
     */
    function removeContractFromWhiteList(address contractAddress) external;

    /**
     * @dev Adds factory to whitelist
     *
     * Requirements:
     *
     * - `factoryAddress` cannot be the zero address.
     * - `factoryAddress` must not exists.
     *
     * Emits a {FactoryAdded} event.
     */
    function addFactoryToWhiteList(address factoryAddress) external;

    /**
     * @dev Removes factory from whitelist
     *
     * Requirements:
     *
     * - `factoryAddress` cannot be the zero address.
     * - `factoryAddress` must exists.
     *
     * Emits a {FactoryRemoved} event.
     */
    function removeFactoryFromWhiteList(address factoryAddress) external;
}
