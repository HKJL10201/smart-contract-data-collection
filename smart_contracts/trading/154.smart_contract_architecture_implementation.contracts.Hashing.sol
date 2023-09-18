// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/**
@title Hashing
A contract that provides hash-related functions and signature verification.
*/
contract Hashing {
    using ECDSA for bytes32;

    /**
    Generates a message hash based on the contract address, balances, and nonce.
    @param _contractAddress The address of the contract.
    @param _balances The array of balances.
    @param _nonce The nonce value.
    @return The generated message hash.
    */
    function getMessage(
        address _contractAddress,
        uint256[2] memory _balances,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_contractAddress, _balances, _nonce));
    }

    /**
    Verifies the signature against a message hash.
    @param _msgHash The message hash.
    @param _signature The signature to verify.
    @return The address of the signer.
    */
    function verify(bytes32 _msgHash, bytes memory _signature) public pure returns (address) {
        bytes32 _ethSignedMessageHash = getEthSignedMessageHash(_msgHash);
        return _ethSignedMessageHash.recover(_signature);
    }

    /**
    Verifies if a signature is valid for a given signer and message hash.
    @param _signer The address of the signer.
    @param _msgHash The message hash.
    @param _signature The signature to verify.
    @return True if the signature is valid, false otherwise.
    */
    function verify(address _signer, bytes32 _msgHash, bytes memory _signature) public pure returns (bool) {
        bytes32 _ethSignedMessageHash = getEthSignedMessageHash(_msgHash);
        address recovered = _ethSignedMessageHash.recover(_signature);

        return recovered == _signer;
    }

    /**
    Checks if a signature is valid for a given signer and message hash.
    @param _signer The address of the signer.
    @param _msgHash The message hash.
    @param _signature The signature to verify.
    @return True if the signature is valid, false otherwise.
    */
    function checkSignature(address _signer, bytes32 _msgHash, bytes memory _signature) public view returns (bool) {
        return SignatureChecker.isValidSignatureNow(_signer, _msgHash, _signature);
    }

    /**
    Generates a random hash based on the current block number.
    @return The generated random hash.
    */
    function rndHash() public view returns (bytes32) {
        return keccak256(abi.encodePacked(block.number));
    }

    /**
    Converts a message hash to its Ethereum signed message hash format.
    @param messageHash The message hash.
    @return The Ethereum signed message hash.
    */
    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        return messageHash.toEthSignedMessageHash();
    }
}
