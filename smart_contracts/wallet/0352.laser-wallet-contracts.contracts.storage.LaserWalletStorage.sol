// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import {WalletConfig} from "../interfaces/ILaserState.sol";

/**
 * @title LaserWalletStorage
 *
 * @notice Contract that maps the storage of Laser wallet.
 */
abstract contract LaserWalletStorage {
    // LaserState.sol
    address public singleton;

    address public owner;

    uint256 public nonce;

    uint256 internal guardianCount;

    uint256 internal recoveryOwnerCount;

    mapping(address => address) public guardians;

    mapping(address => address) public recoveryOwners;

    WalletConfig walletConfig;
}
