// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IImplementationProvider {
    function getImplementation() external view returns (address);
}
