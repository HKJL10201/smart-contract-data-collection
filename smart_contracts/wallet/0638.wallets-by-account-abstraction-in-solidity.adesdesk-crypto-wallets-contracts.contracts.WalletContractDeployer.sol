// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './WalletContract.sol';

contract WalletContractDeployer {
    struct Wallet {
        address owner;
        address walletAddress;
    }

    mapping(address => Wallet) private wallets; // Mapping to store the wallet details by owner address
    mapping(address => address) private ownerToWallet; // Mapping to map owner address to wallet address

    event WalletCreated(address indexed owner, address indexed walletAddress); // Event emitted when a new wallet is created
    event Transfer(address indexed from, address indexed to, uint256 amount); // Event emitted when a transfer occurs between wallets

    function createWallet() external {
        require(wallets[msg.sender].owner == address(0), "Wallet already exists"); // Check if the wallet for the caller already exists

        address newWalletAddress = address(new WalletContract(msg.sender)); // Create a new wallet contract with the caller as the owner
        wallets[msg.sender] = Wallet(msg.sender, newWalletAddress); // Store the wallet details in the wallets mapping
        ownerToWallet[msg.sender] = newWalletAddress; // Map the owner address to the wallet address

        emit WalletCreated(msg.sender, newWalletAddress); // Emit an event to notify that a new wallet has been created
    }

    function getBalance(address walletOwner) external view returns (uint256) {
        WalletContract wallet = WalletContract(payable(ownerToWallet[walletOwner])); // Create an instance of the wallet contract for the specified owner
        return wallet.getBalance(); // Retrieve the Ether balance of the wallet
    }

    function getTokenBalance(address walletOwner, address tokenAddress) external view returns (uint256) {
        WalletContract wallet = WalletContract(payable(ownerToWallet[walletOwner])); // Create an instance of the wallet contract for the specified owner
        return wallet.getTokenBalance(tokenAddress); // Retrieve the token balance of the wallet for the specified token address
    }

    function getWalletOwner(address walletAddress) external view returns (address) {
        return wallets[walletAddress].owner; // Retrieve the owner address of a specified wallet address
    }

    function getWalletAddress(address walletOwner) external view returns (address) {
        return ownerToWallet[walletOwner]; // Retrieve the wallet address of a specified wallet owner
    }

    function transfer(address fromWalletAddress, address toWalletAddress, address token, uint256 amount) external {
        require(wallets[fromWalletAddress].owner != address(0), "Sender wallet does not exist"); // Check if the sender wallet exists
        require(wallets[toWalletAddress].owner != address(0), "Receiver wallet does not exist"); // Check if the receiver wallet exists

        WalletContract fromWallet = WalletContract(payable(fromWalletAddress)); // Create an instance of the sender wallet contract

        require(fromWallet.getBalance() >= amount, "Insufficient balance"); // Check if the sender wallet has sufficient balance for the transfer

        fromWallet.transfer(toWalletAddress, token, amount); // Perform the transfer between wallets
        emit Transfer(fromWalletAddress, toWalletAddress, amount); // Emit an event to notify the transfer
    }
}