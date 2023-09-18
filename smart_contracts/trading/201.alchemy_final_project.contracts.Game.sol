// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Game {
    struct Asset {
        uint assetId;
        uint price;
        address owner;
    }
    Asset[] public assets;
    address[] public administrators;
    // events to transfer,create and change price. these function are available only to administrators so i make it easy for users to check their actions.
    event Transfer(address indexed from, address indexed _recipient, uint assetId);
    event Create(uint _assetId, uint _price);
    event PriceChange(uint _assetId, uint _oldPrice, uint _newPrice);

    constructor() {
        administrators.push(msg.sender);
    }

    // Modifier to check if the caller is an administrator
    modifier onlyAdministrator() {
        bool isAdmin = false;
        for (uint i = 0; i < administrators.length; i++) {
            if (administrators[i] == msg.sender) {
                isAdmin = true;
                break;
            }
        }
        require(isAdmin, "Admins only");
        _;
    }

    // Function to add a new administrator address (only callable by existing administrators)
    function addAdministrator(address _newAdmin) external onlyAdministrator {
        // Check if the address is not already an administrator
        for (uint i = 0; i < administrators.length; i++) {
            require(administrators[i] != _newAdmin, "Address is already an administrator");
        }
        administrators.push(_newAdmin);
    }

    function createAsset(uint _assetId, uint _price) onlyAdministrator external {
        assets.push(Asset(_assetId, _price, msg.sender));
        emit Create(_assetId, _price);
    }

    function transfer(address _recipient, uint _assetId) onlyAdministrator external {
        // Find the asset with the given assetId owned by the sender (msg.sender)
        uint assetIndex;
        bool assetFound;
        (assetIndex, assetFound) = findAssetIndex(_assetId);
        require(assetFound, "Asset not found");

        // Make sure the sender is the current owner of the asset
        require(assets[assetIndex].owner == msg.sender, "You don't own this asset");

        // Transfer the asset to the recipient
        assets[assetIndex].owner = _recipient;
        // emit Transfer event
        emit Transfer(msg.sender, _recipient, _assetId);
    }

    function buy(uint _assetId) external payable {
        // Find the asset with the given assetId
        uint assetIndex;
        bool assetFound;
        (assetIndex, assetFound) = findAssetIndex(_assetId);
        require(assetFound, "Asset not found");

        // Make sure the asset is not already owned by the sender
        require(assets[assetIndex].owner != msg.sender, "You already own this asset");

        // Make sure the sent Ether matches the asset price
        require(msg.value == assets[assetIndex].price, "Incorrect Ether value");

        // Transfer ownership of the asset to the buyer
        address previousOwner = assets[assetIndex].owner;
        assets[assetIndex].owner = msg.sender;

        // Transfer the payment to the previous owner
        (bool success, ) = previousOwner.call{value: msg.value}("");
        require(success, "Transfer failed");

        emit Transfer(previousOwner, msg.sender, _assetId);
    }

    function changePrice(uint _assetId, uint _newPrice) external onlyAdministrator {
        // find the asset with the given asset ID
        uint assetIndex;
        bool assetFound;
        (assetIndex, assetFound) = findAssetIndex(_assetId);
        require(assetFound, "Asset not found");
        // change the price of the asset
        uint oldPrice = assets[assetIndex].price;
        assets[assetIndex].price = _newPrice;

        emit PriceChange(_assetId, oldPrice, _newPrice);
    }

    // Helper function to find the index of the asset with the given assetId
    function findAssetIndex(uint _assetId) internal view returns (uint index, bool found) {
        for (uint i = 0; i < assets.length; i++) {
            if (assets[i].assetId == _assetId) {
                return (i, true); 
            }
        }
        return (0, false); 
    }
}