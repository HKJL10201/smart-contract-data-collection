// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {NounsTrade} from "../src/NounsTrade.sol";

interface ImmutableCreate2Factory {
    function safeCreate2(bytes32 salt, bytes calldata initCode) external payable returns (address deploymentAddress);
    function findCreate2Address(bytes32 salt, bytes calldata initCode)
        external
        view
        returns (address deploymentAddress);
    function findCreate2AddressViaHash(bytes32 salt, bytes32 initCodeHash)
        external
        view
        returns (address deploymentAddress);
}

contract Deploy is Script {
    ImmutableCreate2Factory immutable factory = ImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);
    address nounsTokenAddr = 0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03;
    address owner = 0x2953c99fc4262350e0312132a92aA5bA1553249D;
    bytes bytecode = type(NounsTrade).creationCode;
    bytes initCode = abi.encodePacked(bytecode, abi.encode(owner, nounsTokenAddr));
    bytes32 salt = 0x00005ba0551422e2112688b0ed7c40fea6c0c60fb41ab3f8e4cbb2038f5fc028;

    function run() external {
        vm.startBroadcast();

        address nounsTradeAddr = factory.safeCreate2(salt, initCode);
        NounsTrade trade = NounsTrade(nounsTradeAddr);
        console2.log(address(trade));

        vm.stopBroadcast();
    }
}
