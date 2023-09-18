// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "../core/BaseAccount.sol";
import "hardhat/console.sol";

contract MockAccount {
    using ECDSA for bytes32;
    address constant owner = 0x3Eea25034397B249a3eD8614BB4d0533e5b03594;

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) public view returns (uint256 validationData) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (owner != hash.recover(userOp.signature)) return 1;
        return 0;
    }
}
