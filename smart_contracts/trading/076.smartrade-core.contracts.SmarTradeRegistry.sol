// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./interfaces/ISmarTradeRegistry.sol";

/**
 * @dev SmarTradeRegistry Standard basic implementation
 */
contract SmarTradeRegistry is Context, AccessControl, ERC165, ISmarTradeRegistry {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant SUPER_ROLE = keccak256("SUPER_ROLE");
    bytes32 public constant DELEGATOR_ROLE = keccak256("DELEGATOR_ROLE");

    // The set of contracts
    EnumerableSet.AddressSet private _contractWhiteList;

    // The set of factories
    EnumerableSet.AddressSet private _factoryWhiteList;

    /*
     *     bytes4(keccak256('isContractWhiteListed(address)')) == 0x36bfae1d
     *     bytes4(keccak256('isFactoryWhiteListed(address)')) == 0x3c8ae9b5
     *     bytes4(keccak256('addContractToWhiteList(address)')) == 0x9ddfbe36
     *     bytes4(keccak256('removeContractFromWhiteList(address)')) == 0xc2538faa
     *     bytes4(keccak256('addFactoryToWhiteList(address)')) == 0x1b2dd14d
     *     bytes4(keccak256('removeFactoryFromWhiteList(address)')) == 0x7fc48c7e
     *
     *     => 0x36bfae1d ^ 0x3c8ae9b5 ^ 0x9ddfbe36 ^ 0xc2538faa ^
     *        0x1b2dd14d ^ 0x7fc48c7e == 0x31502b07
     */
    bytes4 private constant _INTERFACE_ID_SMARTRADEREGISTRY = 0x31502b07;

    /**
     * @dev Initializes the contract.
     */
    constructor () public {
        _setupRole(SUPER_ROLE, _msgSender());
        _setupRole(DELEGATOR_ROLE, _msgSender());

        // Sets each role admin to super role
        _setRoleAdmin(DELEGATOR_ROLE, SUPER_ROLE);
        _setRoleAdmin(SUPER_ROLE, SUPER_ROLE);

        // register the supported interfaces to conform to SmarTradeRegistry via ERC165
        _registerInterface(_INTERFACE_ID_SMARTRADEREGISTRY);
    }

    /**
     * @dev See {ISmarTradeRegistry-isContractWhiteListed}.
     */
    function isContractWhiteListed(address contractAddress) public view override returns (bool) {
        return _contractWhiteList.contains(contractAddress);
    }

    /**
     * @dev See {ISmarTradeRegistry-isFactoryWhiteListed}.
     */
    function isFactoryWhiteListed(address contractAddress) public view override returns (bool) {
        return _factoryWhiteList.contains(contractAddress);
    }

    /**
     * @dev Returns contract whitelist.
     */
    function getContractWhiteList() public view returns (address[] memory) {
      address[] memory contractWhiteList = new address[](_contractWhiteList.length());

      for (uint256 i = 0; i < _contractWhiteList.length(); i++) {
          contractWhiteList[i] = _contractWhiteList.at(i);
      }

      return contractWhiteList;
    }

    /**
     * @dev Returns factory whitelist.
     */
    function getFactoryWhiteList() public view returns (address[] memory) {
      address[] memory factoryWhiteList = new address[](_factoryWhiteList.length());

      for (uint256 i = 0; i < _factoryWhiteList.length(); i++) {
          factoryWhiteList[i] = _factoryWhiteList.at(i);
      }

      return factoryWhiteList;
    }

    /**
     * @dev See {ISmarTradeRegistry-addContractToWhiteList}.
     */
    function addContractToWhiteList(address contractAddress) public virtual override {
        require(
            hasRole(DELEGATOR_ROLE, _msgSender()) || hasRole(SUPER_ROLE, _msgSender()),
            "SmarTradeRegistry: must have delegator or super role to add contract to whitelist"
        );
        require(
            contractAddress != address(0),
            "SmarTradeRegistry: contract cannot be the zero address"
        );
        require(
            !_contractWhiteList.contains(contractAddress),
            "SmarTradeRegistry: contract must not exists"
        );

        _contractWhiteList.add(contractAddress);

        emit ContractAdded(contractAddress, _msgSender());
    }

    /**
     * @dev See {ISmarTradeRegistry-removeContractFromWhiteList}.
     */
    function removeContractFromWhiteList(address contractAddress) public virtual override {
        require(
            hasRole(SUPER_ROLE, _msgSender()),
            "SmarTradeRegistry: must have super role to remove contract from whitelist"
        );
        require(
            contractAddress != address(0),
            "SmarTradeRegistry: contract cannot be the zero address"
        );
        require(
            _contractWhiteList.contains(contractAddress),
            "SmarTradeRegistry: contract must exists"
        );

        _contractWhiteList.remove(contractAddress);

        emit ContractRemoved(contractAddress, _msgSender());
    }

    /**
     * @dev See {ISmarTradeRegistry-addFactoryToWhiteList}.
     */
    function addFactoryToWhiteList(address factoryAddress) public virtual override {
        require(
            hasRole(SUPER_ROLE, _msgSender()),
            "SmarTradeRegistry: must have super role to add factory to whitelist"
        );
        require(
            factoryAddress != address(0),
            "SmarTradeRegistry: factory cannot be the zero address"
        );
        require(
            !_factoryWhiteList.contains(factoryAddress),
            "SmarTradeRegistry: factory must not exists"
        );

        _factoryWhiteList.add(factoryAddress);

        emit FactoryAdded(factoryAddress, _msgSender());
    }

    /**
     * @dev See {ISmarTradeRegistry-removeFactoryFromWhiteList}.
     */
    function removeFactoryFromWhiteList(address factoryAddress) public virtual override {
        require(
            hasRole(SUPER_ROLE, _msgSender()),
            "SmarTradeRegistry: must have super role to remove factory from whitelist"
        );
        require(
            factoryAddress != address(0),
            "SmarTradeRegistry: factory cannot be the zero address"
        );
        require(
            _factoryWhiteList.contains(factoryAddress),
            "SmarTradeRegistry: factory must exists"
        );

        _factoryWhiteList.remove(factoryAddress);

        emit FactoryRemoved(factoryAddress, _msgSender());
    }
}
