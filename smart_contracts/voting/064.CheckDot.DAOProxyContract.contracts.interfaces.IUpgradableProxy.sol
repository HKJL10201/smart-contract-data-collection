// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IOwnedProxy.sol";

/**
 * @title IUpgradableProxyDAO
 * @author Jeremy Guyet (@jguyet)
 * @dev See {UpgradableProxy}.
 */
interface IUpgradableProxy is IOwnedProxy {

    function getImplementation() external view returns (address);

    function getOwner() external view returns (address);

    function transferOwnership(address _newOwner) external payable;

    function upgrade(address _newAddress, address _newStoreAddress) external payable;

}