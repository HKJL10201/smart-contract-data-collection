// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IOwnedProxy.sol";
import "../utils/ProxyUpgrades.sol";

/**
 * @title IUpgradableProxyDAO
 * @author Jeremy Guyet (@jguyet)
 * @dev See {UpgradableProxyDAO}.
 */
interface IUpgradableProxyDAO is IOwnedProxy {

    function getImplementation() external view returns (address);

    function getOwner() external view returns (address);

    function getGovernance() external view returns (address);

    function transferOwnership(address _newOwner) external payable;

    function upgrade(address _newAddress, address _newStoreAddress, uint256 _utcStartVote, uint256 _utcEndVote) external payable;

    function voteUpgradeCounting() external payable;

    function voteUpgrade(bool approve) external payable;

    function getAllUpgrades() external view returns (ProxyUpgrades.Upgrade[] memory);

    function getLastUpgrade() external view returns (ProxyUpgrades.Upgrade memory);
}