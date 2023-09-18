//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IProtocolControl} from "../interfaces/IProtocolControl.sol";

import {Escrow} from "./Escrow.sol";
import {Mimic} from "./Mimic.sol";
import {ExecutionEnvironment} from "./ExecutionEnvironment.sol";
import {Permit69} from "./Permit69.sol";

import "../types/CallTypes.sol";

import "forge-std/Test.sol";

contract Factory is Test, Escrow, Permit69 {
    //address immutable public atlas;
    bytes32 public immutable salt;
    address public immutable execution;

    constructor(uint32 _escrowDuration) Escrow(_escrowDuration) {
        //atlas = msg.sender;
        salt = keccak256(abi.encodePacked(block.chainid, atlas, "Atlas 1.0"));

        execution =
            _deployExecutionEnvironmentTemplate(address(this), ProtocolCall({to: address(0), callConfig: uint16(0)}));
    }

    // GETTERS
    function environment() public view override returns (address _environment) {
        _environment = activeEnvironment;
    }

    function getEscrowAddress() external view returns (address escrowAddress) {
        escrowAddress = atlas;
    }

    function getExecutionEnvironment(UserCall calldata userCall, address protocolControl)
        external
        view
        returns (address executionEnvironment)
    {
        executionEnvironment = _getExecutionEnvironment(userCall.metaTx.from, protocolControl.codehash, protocolControl);
    }

    function _getExecutionEnvironment(address user, bytes32 controlCodeHash, address protocolControl)
        internal
        view
        returns (address executionEnvironment)
    {
        ProtocolCall memory protocolCall = IProtocolControl(protocolControl).getProtocolCall();
        
        executionEnvironment = _getExecutionEnvironmentCustom(user, controlCodeHash, protocolCall.to, protocolCall.callConfig);
    }

    // NOTE: This func is used to generate the address of user ExecutionEnvironments that have
    // been deprecated due to ProtocolControl changes of callConfig.
    function _getExecutionEnvironmentCustom(address user, bytes32 controlCodeHash, address protocolControl, uint16 callConfig)
        internal
        view
        override
        returns (address executionEnvironment)
    {
        executionEnvironment = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            keccak256(
                                abi.encodePacked(
                                    _getMimicCreationCode(
                                        protocolControl, callConfig, execution, user, controlCodeHash
                                    )
                                )
                            )
                        )
                    )
                )
            )
        );
    }

    function _setExecutionEnvironment(ProtocolCall calldata protocolCall, address user, bytes32 controlCodeHash)
        internal
        returns (address executionEnvironment)
    {
        bytes memory creationCode =
            _getMimicCreationCode(protocolCall.to, protocolCall.callConfig, execution, user, controlCodeHash);

        executionEnvironment = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            keccak256(abi.encodePacked(creationCode))
                        )
                    )
                )
            )
        );

        if (executionEnvironment.codehash == bytes32(0)) {
            bytes32 memSalt = salt;
            assembly {
                executionEnvironment := create2(0, add(creationCode, 32), mload(creationCode), memSalt)
            }
        }
    }

    function _deployExecutionEnvironmentTemplate(address, ProtocolCall memory) internal returns (address executionEnvironment) {
        ExecutionEnvironment _environment = new ExecutionEnvironment{
            salt: salt
        }(atlas);

        executionEnvironment = address(_environment);
    }

    function _getMimicCreationCode(
        address protocolControl,
        uint16 callConfig,
        address executionLib,
        address user,
        bytes32 controlCodeHash
    ) internal pure returns (bytes memory creationCode) {
        // NOTE: Changing compiler settings or solidity versions can break this.
        creationCode = type(Mimic).creationCode;
        assembly {
            mstore(add(creationCode, 85), add(shl(96, executionLib), 0x73ffffffffffffffffffffff))
            mstore(add(creationCode, 131), add(shl(96, user), 0x73ffffffffffffffffffffff))
            mstore(
                add(creationCode, 152),
                add(shl(96, protocolControl), add(add(shl(88, 0x61), shl(72, callConfig)), 0x7f0000000000000000))
            )
            mstore(add(creationCode, 176), controlCodeHash)
        }
    }
}
