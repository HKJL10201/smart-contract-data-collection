// SPDX-License-Identifier: MIT only

pragma solidity ^0.8.0;

import "./BaseService.sol";
import "./interfaces/ITransferStorage.sol";

/**
* @title TransactionControlService
* @notice Default singleton service for issuing transactions through a MasterCoin Wallet.
* @dev To be upgraded with EIP-4337 via a useroperation pool support and batched transactions
*/
contract TransactionControlService is BaseService {

    bytes4 private constant ERC20_TRANSFER = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant ERC20_APPROVE = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant ERC721_SET_APPROVAL_FOR_ALL = bytes4(keccak256("setApprovalForAll(address,bool)"));
    bytes4 private constant ERC721_TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM_BYTES = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
    bytes4 private constant ERC1155_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)"));

    ITransferStorage internal immutable userWhitelist;
    event AddedToWhitelist(address indexed wallet, address indexed target, uint64 whitelistAfter);
    event RemovedFromWhitelist(address indexed wallet, address indexed target);
    uint256 internal immutable whitelistPeriod;

    constructor(uint256 _whitelistPeriod) BaseService("TransactionControlService") {
        // Time in seconds before whitelist entry is disabled
        whitelistPeriod = _whitelistPeriod;
        userWhitelist = ITransferStorage(address(this));
    }

    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    /**
    * @notice Executes a transaction batch on behalf of a wallet.
    * @param _wallet The target wallet.
    * @param _transactions The transactions to execute.
    * @dev method is meant to issue transactions from a MasterCoin wallet to another smart contract
    */
    function batchCall(
        address _wallet,
        Call[] calldata _transactions
    )
        external
        onlyWalletOwnerOrSelf(_wallet)
        onlyWhenUnlocked(_wallet)
        returns (bytes[] memory)
    {
        bytes[] memory txs = new bytes[](_transactions.length);
        for(uint i = 0; i < _transactions.length; i++) {
            address spender = recoverSpender(_transactions[i].to, _transactions[i].data);
            require(
                (_transactions[i].value == 0 || spender == _transactions[i].to) &&
                isWhitelisted(_wallet, spender),
                "Call not authorised");
            txs[i] = invokeWallet(_wallet, _transactions[i].to, _transactions[i].value, _transactions[i].data);
        }
        return txs;
    }

    function recoverSpender(address _to, bytes memory _data) internal pure returns (address spender) {
        if(_data.length >= 68) {
            bytes4 methodId;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                methodId := mload(add(_data, 0x20))
            }
            if(
                methodId == ERC20_TRANSFER ||
                methodId == ERC20_APPROVE ||
                methodId == ERC721_SET_APPROVAL_FOR_ALL) 
            {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    spender := mload(add(_data, 0x24))
                }
                return spender;
            }
            if(
                methodId == ERC721_TRANSFER_FROM ||
                methodId == ERC721_SAFE_TRANSFER_FROM ||
                methodId == ERC721_SAFE_TRANSFER_FROM_BYTES ||
                methodId == ERC1155_SAFE_TRANSFER_FROM)
            {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    spender := mload(add(_data, 0x44))
                }
                return spender;
            }
        }

        spender = _to;
    }

    function isWhitelisted(address _wallet, address _target) internal view returns (bool _isWhitelisted) {
        uint whitelistAfter = userWhitelist.isWhiteListed(_wallet, _target);
        return whitelistAfter > 0 && whitelistAfter < block.timestamp;
    }

    function setWhitelist(address _wallet, address _target, uint256 _whitelistAfter) internal {
        userWhitelist.addToWhitelist(_wallet, _target, _whitelistAfter);
    }

    function addToWhitelist(address _wallet, address _target) external onlyWalletOwnerOrSelf(_wallet) onlyWhenUnlocked(_wallet) {
        require(_target != _wallet, "Cannot whitelist wallet");
        require(!isWhitelisted(_wallet, _target), "Target already whitelisted");

        uint256 whitelistAfter = block.timestamp + whitelistPeriod;
        setWhitelist(_wallet, _target, whitelistAfter);
        emit AddedToWhitelist(_wallet, _target, uint64(whitelistAfter));
    }

    function removeFromWhitelist(address _wallet, address _target) external onlyWalletOwnerOrSelf(_wallet) onlyWhenUnlocked(_wallet) {
        setWhitelist(_wallet, _target, 0);
        emit RemovedFromWhitelist(_wallet, _target);
    }
}