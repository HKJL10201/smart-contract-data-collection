//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleWalletAuthorization {

    address public owner;
    mapping(address => bool) public authorizedAddresses;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only the owner is authorized to transact this");
        _;
    }

    function addWallet(address _addr) public onlyOwner {
        authorizedAddresses[_addr] = true;
    }

    function revokeWallet(address _addr) public onlyOwner {
        authorizedAddresses[_addr] = false;
    }
}
