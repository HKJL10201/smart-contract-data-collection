//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Interface to call transferOwnership on deployed proxy
interface IOwnership {
    function transferOwnership(address newOwner) external;
}
