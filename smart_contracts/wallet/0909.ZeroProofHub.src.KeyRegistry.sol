// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title KeyRegistry
 * @dev This contract allows users to register a public key and a proxy contract 
 *      address that will be used for privacy enhanced transactions via zk-SNARKs.
 */
contract KeyRegistry {

    error Public_key_already_registered_for_this_address();
    error No_public_key_registered_for_this_address();

    /**
     * @dev A struct to represent a User, storing their proxy contract and public key.
     */
    struct User {
        address proxyContract; // Address of the user's proxy contract
        bytes publicKey; // User's public key for zk-SNARKs
        bool isValue; // A boolean value to confirm existence of a user
    }
    
    // Mapping from user's address to their User struct
    mapping (address => User) private users;

    // Event triggered when a public key is registered
    event KeyRegistered(address indexed user, bytes publicKey, address proxyContract);

    // Event triggered when a public key is updated
    event KeyUpdated(address indexed user, bytes newPublicKey);

    /**
     * @dev Function to register a public key and proxy contract for the sender's address
     * @param publicKey User's public key for zk-SNARKs
     * @param proxyContract User's proxy contract address
     */
    function registerKey(bytes memory publicKey, address proxyContract) public {
        if(users[msg.sender].isValue) revert Public_key_already_registered_for_this_address();

        users[msg.sender] = User(proxyContract, publicKey, true);

        emit KeyRegistered(msg.sender, publicKey, proxyContract);
    }

    /**
     * @dev Function to retrieve the public key and proxy contract of a given user address
     * @param userAddress Address of the user whose public key is to be retrieved
     * @return publicKey The public key of the user
     * @return proxyContract The proxy contract address of the user
     */
    function getKey(address userAddress) public view returns (bytes memory publicKey, address proxyContract) {
        if(!users[userAddress].isValue) revert No_public_key_registered_for_this_address();

        publicKey = users[userAddress].publicKey;
        proxyContract = users[userAddress].proxyContract;
    }

    /**
     * @dev Function to update the public key for the sender's address
     * @param newPublicKey New public key to be updated for the user
     */
    function updateKey(bytes memory newPublicKey) public {
        if(!users[msg.sender].isValue) revert No_public_key_registered_for_this_address();

        users[msg.sender].publicKey = newPublicKey;

        emit KeyUpdated(msg.sender, newPublicKey);
    }
}