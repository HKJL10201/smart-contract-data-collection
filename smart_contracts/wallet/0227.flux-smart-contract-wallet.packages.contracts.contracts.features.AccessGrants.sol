// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;


contract AccessGrants {
    bytes4 constant OWNER = bytes4(keccak256('OWNER'));
    bytes4 constant SWITCH_OWNER = bytes4(keccak256('SWITCH_OWNER'));
    bytes4 constant RECOVERY_ACCOUNT = bytes4(keccak256('RECOVERY_ACCOUNT'));

    
    mapping(bytes4 => bool) public allowAllGrant;
    mapping(bytes4 => mapping(address => mapping(bytes4 => bool))) public roleGrantMap;
}