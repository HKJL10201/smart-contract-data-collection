//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ISimplicyWalletDiamond} from "../diamond/ISimplicyWalletDiamond.sol";
import {IGuardianFacet} from "./IGuardianFacet.sol";
import {IRecovery} from "../recovery/IRecovery.sol";
import {ISemaphore} from "../semaphore/ISemaphore.sol";
import {ISemaphoreCoreBase} from "../semaphore/base/SemaphoreCoreBase/ISemaphoreCoreBase.sol";
import {ISemaphoreGroupsBase} from "../semaphore/base/SemaphoreGroupsBase/ISemaphoreGroupsBase.sol";
import {IERC20Service} from "../token/ERC20/IERC20Service.sol";
import {IERC721Service} from "../token/ERC721/IERC721Service.sol";

/**
 * @title zkWallet interface
 */
interface IzkWallet is 
  ISimplicyWalletDiamond, 
  IGuardianFacet,
  IRecovery,
  ISemaphore, 
  ISemaphoreCoreBase, 
  ISemaphoreGroupsBase,
  IERC20Service,
  IERC721Service
{}
