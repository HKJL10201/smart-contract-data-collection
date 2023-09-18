// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRegistry.sol";

contract Registry is Ownable {
    bool allowAllCurrencies;
    address systemWallet;
    uint64 fee;
    uint64 scale;

    event SystemWalletUpdated(address indexed newWallet);
    event FeeChanged(uint256 newFee);
    event ScaleChanged(uint256 newScale);
    event ContractStatusChanged(address indexed changed, bool indexed status);
    event CurrencyStatusChanged(address indexed changed, bool indexed status);

    error AllCurrencyApproved();

    mapping(address => bool) public platformContracts;
    mapping(address => bool) public approvedCurrencies;

    constructor() {
        approvedCurrencies[
            address(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa)
        ] = true;
        // default 3% tax on a 18 decimal asset
        fee = 300;
        scale = 1e4;
    }

    function setSystemWallet(address newWallet) external onlyOwner {
        systemWallet = newWallet;

        emit SystemWalletUpdated(newWallet);
    }

    function setFee(uint64 newFee) external onlyOwner {
        fee = newFee;
        emit FeeChanged(newFee);
    }

    function setScale(uint64 newScale) external onlyOwner {
        scale = newScale;
        emit ScaleChanged(newScale);
    }

    function setContractStatus(address nftContract, bool status)
        external
        onlyOwner
    {
        if (platformContracts[nftContract] != status) {
            platformContracts[nftContract] = status;
            emit ContractStatusChanged(nftContract, status);
        }
    }

    function setCurrencyStatus(address tokenContract, bool status)
        external
        onlyOwner
    {
        if (allowAllCurrencies) revert AllCurrencyApproved();

        if (approvedCurrencies[tokenContract] != status) {
            approvedCurrencies[tokenContract] = status;
            emit CurrencyStatusChanged(tokenContract, status);
        }
    }

    function approveAllCurrencies() external onlyOwner {
        if (!allowAllCurrencies) {
            allowAllCurrencies = true;
            emit CurrencyStatusChanged(address(0), true);
        }
    }

    function feeInfo(uint256 salePrice)
        external
        view
        returns (address, uint256)
    {
        return (systemWallet, ((salePrice * fee) / scale));
    }
}