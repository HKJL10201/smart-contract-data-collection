// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title IOwnedProxy
 * @author Jeremy Guyet (@jguyet)
 * @dev See {UpgradableProxyDAO}.
 */
interface IOwnedProxy {

    function getOwner() external view returns (address);

    function transferOwnership(address _newOwner) external payable;
}