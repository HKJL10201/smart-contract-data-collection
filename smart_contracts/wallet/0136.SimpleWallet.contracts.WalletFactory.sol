pragma solidity ^0.8.0;

import "./Wallet.sol";

contract WalletFactory {
    event NewWallet(address wallet);

    // new mapping from address -> wallet address
    mapping(address => address) public wallets;
    
    function createWallet() public returns (address) {
        Wallet wallet = new Wallet(msg.sender);
        emit NewWallet(address(wallet));
        wallets[msg.sender] = address(wallet);
        return address(wallet);
    }
}
