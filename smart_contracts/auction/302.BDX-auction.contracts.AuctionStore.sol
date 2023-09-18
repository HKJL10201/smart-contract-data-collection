//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract BigDataExchangeStore {
    address admin;
    address[] auctions;
    address[] factories;

    constructor() {
        admin = msg.sender;
    }

    function store(address _addr) external {
        auctions.push(_addr);
    }

    function storeFactory(address _addr) external {
        factories.push(_addr);
    }
}
