// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console} from 'forge-std/console.sol';
import {stdStorage, StdStorage, Test} from 'forge-std/Test.sol';

import "../src/KeyRegistry.sol";

contract KeyRegistryTest is Test {
    KeyRegistry keyRegistry;

    function setUp() public {
        keyRegistry = new KeyRegistry();
    }

    function test_RegisterKey() public {
        bytes memory publicKey = "0x123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0";
        address proxyContract = address(this);
        keyRegistry.registerKey(publicKey, proxyContract);
        (bytes memory retrievedPublicKey, address retrievedProxyContract) = keyRegistry.getKey(address(this));
        assertEq(retrievedPublicKey, publicKey, "The public key should match the one that was set");
        assertEq(retrievedProxyContract, proxyContract, "The proxy contract should match the one that was set");
    }

    function test_GetKey() public {
        bytes memory publicKey = "0x123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0";
        address proxyContract = address(this);
        keyRegistry.registerKey(publicKey, proxyContract);
        (bytes memory retrievedPublicKey, address retrievedProxyContract) = keyRegistry.getKey(address(this));
        assertEq(retrievedPublicKey, publicKey, "The public key should match the one that was set");
        assertEq(retrievedProxyContract, proxyContract, "The proxy contract should match the one that was set");
    }

    function test_UpdateKey() public {
        bytes memory publicKey1 = "0x123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0";
        bytes memory publicKey2 = "0xabcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789";
        address proxyContract = address(this);
        keyRegistry.registerKey(publicKey1, proxyContract);
        keyRegistry.updateKey(publicKey2);
        (bytes memory updatedPublicKey, address retrievedProxyContract) = keyRegistry.getKey(address(this));
        assertEq(updatedPublicKey, publicKey2, "The public key should match the one that was updated");
        assertEq(retrievedProxyContract, proxyContract, "The proxy contract should match the one that was set");
    }

    function test_CannotRegisterTwice() public {
        bytes memory publicKey = "0x123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0";
        address proxyContract = address(this);
        keyRegistry.registerKey(publicKey, proxyContract);
        (bool success,) = address(keyRegistry).call(abi.encodePacked(keyRegistry.registerKey.selector, publicKey, proxyContract));
        assertEq(success, false, "Second registration should fail");
    }
}