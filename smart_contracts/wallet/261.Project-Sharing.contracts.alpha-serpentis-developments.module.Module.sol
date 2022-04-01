// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ModuleInterface.sol";

abstract contract Module is ModuleInterface {
    // Address of the owner of the module
    address public immutable owner;
    // Address of the module implementation
    address public implementation;
    // Immutable bool that determines if the implementation address can change
    bool public immutable allowImplementationChange;

    constructor(address _owner, address _implementation, bool _allowImplementationChange) {
        require(
            _owner != address(0),
            "Module: zero address"
        );
        require(
            _implementation != address(0),
            "Module: zero address"
        );
        owner = _owner;
        implementation = _implementation;
        allowImplementationChange = _allowImplementationChange;
    }

    function changeImplementation(address _newImplementation) external {
        require(
            _newImplementation != address(0),
            "Module: zero address"
        );
        require(
            allowImplementationChange,
            "Module: Implementation is immutable"
        );
        require(
            msg.sender == owner,
            "Module: only owner function"
        );
        implementation = _newImplementation;
    }
}