// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ISemaphoreCoreBaseInternal} from "./ISemaphoreCoreBaseInternal.sol";
import {SemaphoreCoreBaseInternal} from "./SemaphoreCoreBaseInternal.sol";

abstract contract SemaphoreCoreBase is ISemaphoreCoreBaseInternal, SemaphoreCoreBaseInternal {}