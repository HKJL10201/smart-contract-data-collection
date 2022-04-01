// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface ModuleInterface {
    function execute(bytes memory _data) external returns(bytes memory);
}