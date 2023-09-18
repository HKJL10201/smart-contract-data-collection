// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./multiSig.sol";

/**
 * @title This smart contract serves as MultiSig Wallet Factory that deploys MultiSig Wallet on Chain and stores a list of it
 * @author Contract Developed by Arasomwan Aisosa Goodluck,
 *
 */

contract MultiSigFactory {
    event WalletDeployed(
        string indexed walletName,
        address indexed walletAddress
    );

    mapping(string => address) public deployedWallets;

    function createWallet(
        string memory _walletName,
        address[] memory _owners,
        uint _numConfirmationsRequired
    ) public {
        require(
            deployedWallets[_walletName] == address(0),
            "WalletName AlreadyExist"
        ); //to ensure that no duplicate Wallet Addresses Exist
        MutiSigWallet wallet = new MutiSigWallet(
            _owners,
            _numConfirmationsRequired
        );
        deployedWallets[_walletName] = address(wallet);
        emit WalletDeployed(_walletName, address(wallet));
    }
}
