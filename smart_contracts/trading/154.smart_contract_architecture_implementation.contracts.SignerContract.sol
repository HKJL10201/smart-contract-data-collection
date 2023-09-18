// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
@title SignerContract
A contract for generating and verifying signed messages.
*/
contract SignerContract {
    using ECDSA for bytes32;

    /**
    Generates the message hash for the given parameters.
    @param contractAddress The address of the contract.
    @param signers The array of signer addresses.
    @param balances The array of balances.
    @param nonce The nonce.
    @return The generated message hash.
    */
    function getMessage(
        address contractAddress,
        address[] memory signers,
        uint256[] memory balances,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(contractAddress, signers, balances, nonce));
    }

    /**
    Generates the message hash for the given parameters, including the Ethereum signed message prefix.
    @param contractAddress The address of the contract.
    @param balances The array of balances.
    @param nonce The nonce.
    @return The generated message hash.
    */
    function getMessageNew(
        address contractAddress,
        uint256[] memory balances,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(contractAddress, balances, nonce)).toEthSignedMessageHash();
    }
}
