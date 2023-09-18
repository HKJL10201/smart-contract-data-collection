// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../../interfaces/IRoleManager.sol";
import "../base/BaseOwnable.sol";

/// @title TransferAuthorizer - Manages delegate-role mapping.
/// @author Cobo Safe Dev Team https://www.cobo.com/
contract FlatRoleManager is IFlatRoleManager, BaseOwnable {
    bytes32 public constant NAME = "FlatRoleManager";
    uint256 public constant VERSION = 1;

    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    event DelegateAdded(address indexed delegate, address indexed sender);
    event DelegateRemoved(address indexed delegate, address indexed sender);
    event RoleAdded(bytes32 indexed role, address indexed sender);
    event RoleGranted(bytes32 indexed role, address indexed delegate, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed delegate, address indexed sender);

    EnumerableSet.AddressSet delegates;
    EnumerableSet.Bytes32Set roles;

    /// @dev mapping from `delegate` address => `role` set;
    mapping(address => EnumerableSet.Bytes32Set) delegateToRoles;

    constructor(address _owner) BaseOwnable(_owner) {}

    /// @notice Add new roles without delegates assigned.
    function addRoles(bytes32[] calldata _roles) external onlyOwner {
        for (uint256 i = 0; i < _roles.length; i++) {
            if (roles.add(_roles[i])) {
                emit RoleAdded(_roles[i], msg.sender);
            }
        }
    }

    /// @notice Grant roles to delegates. Roles and delegates should be one-to-one.
    function grantRoles(bytes32[] calldata _roles, address[] calldata _delegates) external onlyOwner {
        require(
            _roles.length > 0 && _roles.length == _delegates.length,
            "FlatRoleManager: Invalid _roles or _delegates"
        );

        for (uint256 i = 0; i < _roles.length; i++) {
            if (!delegateToRoles[_delegates[i]].add(_roles[i])) {
                // If already bound, skip.
                continue;
            }
            // In case when role is not added.
            if (roles.add(_roles[i])) {
                // Only fired when new one is added.
                emit RoleAdded(_roles[i], msg.sender);
            }

            // Emit `DelegateAdded` before `RoleGranted` to allow
            // subgraph event handler to process in sensible order.
            if (delegates.add(_delegates[i])) {
                emit DelegateAdded(_delegates[i], msg.sender);
            }

            emit RoleGranted(_roles[i], _delegates[i], msg.sender);
        }
    }

    /// @notice Revoke roles from delegates. Roles and delegates should be one-to-one.
    function revokeRoles(bytes32[] calldata _roles, address[] calldata _delegates) external onlyOwner {
        require(
            _roles.length > 0 && _roles.length == _delegates.length,
            "FlatRoleManager: Invalid _roles or _delegates"
        );

        for (uint256 i = 0; i < _roles.length; i++) {
            if (!delegateToRoles[_delegates[i]].remove(_roles[i])) {
                continue;
            }

            // Ensure `RoleRevoked` is fired before `DelegateRemoved`
            // so that the event handlers in subgraphs are triggered in the
            // right order.
            emit RoleRevoked(_roles[i], _delegates[i], msg.sender);

            if (delegateToRoles[_delegates[i]].length() == 0) {
                delegates.remove(_delegates[i]);
                emit DelegateRemoved(_delegates[i], msg.sender);
            }
        }
    }

    /// @notice Get all the roles owned by the delegate
    function getRoles(address delegate) external view returns (bytes32[] memory) {
        return delegateToRoles[delegate].values();
    }

    /// @notice Check if the delegate owns the role.
    function hasRole(address delegate, bytes32 role) external view returns (bool) {
        return delegateToRoles[delegate].contains(role);
    }

    /// @notice Get the entire delegates list in the account.
    function getDelegates() external view returns (address[] memory) {
        return delegates.values();
    }

    /// @notice Get the entire roles list in the account.
    function getAllRoles() external view returns (bytes32[] memory) {
        return roles.values();
    }
}
