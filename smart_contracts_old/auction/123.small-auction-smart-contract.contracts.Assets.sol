// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Auction {
    struct Asset {
        string name;
        uint256 value;
        address owner;
    }

    Asset[] public assets;
    uint256 numAssets = 0;
    address manager;
    uint256 mininmumValue;

    constructor() {
        manager = msg.sender;
        createAsset("AAA", 0.0001 ether, manager);
        createAsset("BBB", 0.0001 ether, manager);
        createAsset("CCC", 0.0001 ether, manager);
        createAsset("DDD", 0.0001 ether, manager);
        createAsset("EEE", 0.0001 ether, manager);
    }

    function createAsset(string memory name, uint256 value, address owner) public payable {
        assets.push(Asset({name: name, value: value, owner: owner}));
    }

    function buyAsset(uint index) public payable {
        mininmumValue = assets[index].value;
        require(msg.value >= (mininmumValue * 3 / 2), "Your price must be 50% higher than the current one");
        assets[index].value = msg.value;
        assets[index].owner = msg.sender;
    }

    function getAssets() external view returns(Asset[] memory) {
        return assets;
    }
}