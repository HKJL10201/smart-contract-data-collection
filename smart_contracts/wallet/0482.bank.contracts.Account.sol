// contracts/Account.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Wallet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Account is Ownable{
    // the associated multisignature wallet
    Wallet private wallet;

    string public firstName;
    string public lastName;

    event DepositForwarded(address indexed sender, uint value);

    // deploy the account before setting the associated wallet
    constructor (string memory _first, string memory _last, address[3] memory _owners){
        firstName = _first;
        lastName = _last;

        wallet = new Wallet(_owners);
    }

    //getter method to access the wallet address
    function getWalletAddress() public view returns (address) {
        return address(wallet);
    }

    // getter method to access the wallet signers
    function getWalletSigners() public view returns(address[3] memory){
        return wallet.getApprovers();
    }

    // forward funds to the associated Wallet, exists for security reasons
    // this function should not be called, instead funds should be sent directly to the address
    // of the associated wallet
    receive() external payable {
        if (msg.value > 0){
            // store incoming data for making external call
            address from = msg.sender;
            uint value = msg.value;

            (bool success, ) = address(wallet).call{value: value}('');

            // if successful, emit an event showing the deposit
            if (success) {
                emit DepositForwarded(from, value);
            } 
        }
    }



}