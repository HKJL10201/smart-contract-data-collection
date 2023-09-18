// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./KeeperBase.sol";
import "./KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}
