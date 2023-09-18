//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ExecutionPhase} from "../types/LockTypes.sol";

import {CallBits} from "../libraries/CallBits.sol";

import {GovernanceControl} from "./GovernanceControl.sol";
import {ExecutionBase} from "./ExecutionBase.sol";

import "../types/CallTypes.sol";

import "forge-std/Test.sol";

abstract contract ProtocolControl is Test, GovernanceControl, ExecutionBase {
    address public immutable escrow;
    address public immutable governance;
    address public immutable control;
    uint16 public immutable callConfig;

    constructor(
        address _escrow,
        address _governance,
        CallConfig memory _callConfig
    ) ExecutionBase(_escrow) {
        control = address(this);
        escrow = _escrow;
        governance = _governance;
        callConfig = CallBits.encodeCallConfig(_callConfig);
    }

    // Safety and support functions and modifiers that make the relationship between protocol
    // and FastLane's backend trustless.

    // Modifiers
    modifier validControl() {
        require(control == _control(), "ERR-PC050 InvalidControl");
        _;
    }

    modifier mustBeCalled() {
        require(address(this) == control, "ERR-PC052 MustBeCalled");
        _;
    }

    // Functions
    function stagingCall(UserMetaTx calldata userMetaTx)
        external
        onlyAtlasEnvironment
        validControl
        validPhase(ExecutionPhase.Staging)
        returns (bytes memory)
    {
        return _stagingCall(userMetaTx);
    }

    function userLocalCall(bytes calldata data) 
        external 
        onlyAtlasEnvironment
        validControl
        validPhase(ExecutionPhase.UserCall)
        returns (bytes memory) 
    {
        return CallBits.needsDelegateUser(callConfig) ? _userLocalDelegateCall(data) : _userLocalStandardCall(data);
    }

    function searcherPreCall(bytes calldata data) 
        external 
        onlyAtlasEnvironment
        validControl
        validPhase(ExecutionPhase.SearcherCalls)
        returns (bool)
    {
        return _searcherPreCall(data);
    }

    function searcherPostCall(bytes calldata data) 
        external 
        onlyAtlasEnvironment
        validControl
        validPhase(ExecutionPhase.SearcherCalls)
        returns (bool)
    {
        
        return _searcherPostCall(data);
    }

    function allocatingCall(bytes calldata data) 
        external 
        onlyAtlasEnvironment
        validControl
        validPhase(ExecutionPhase.HandlingPayments)
    {
        return _allocatingCall(data);
    }

    function verificationCall(bytes calldata data) 
        external 
        onlyAtlasEnvironment
        validControl
        validPhase(ExecutionPhase.Verification)
        returns (bool) 
    {
        return _verificationCall(data);
    }

    function validateUserCall(UserMetaTx calldata userMetaTx) 
        external 
        view
        onlyAtlasEnvironment
        validControl
        returns (bool) 
    {
        return _validateUserCall(userMetaTx);
    }

    // View functions
    function userDelegated() external view returns (bool delegated) {
        delegated = CallBits.needsDelegateUser(callConfig);
    }

    function userLocal() external view returns (bool local) {
        local = CallBits.needsLocalUser(callConfig);
    }

    function userDelegatedLocal() external view returns (bool delegated, bool local) {
        delegated = CallBits.needsDelegateUser(callConfig);
        local = CallBits.needsLocalUser(callConfig);
    }

    function requireSequencedNonces() external view returns (bool isSequenced) {
        isSequenced = CallBits.needsSequencedNonces(callConfig);
    }

    function getProtocolCall() external view returns (ProtocolCall memory protocolCall) {
        protocolCall = ProtocolCall({
            to: address(this),
            callConfig: callConfig
        });
    }

    function _getCallConfig() internal view returns (CallConfig memory) {
        return CallBits.decodeCallConfig(callConfig);
    }

    function getCallConfig() external view returns (CallConfig memory) {
        return _getCallConfig();
    }

    function getProtocolSignatory() external view returns (address governanceAddress) {
        governanceAddress = governance;
    }
}
