// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.21;

import "../libraries/LibStorage.sol";
import {AccountMetadata, IAccountMeta} from "../interfaces/IAccountMeta.sol";
import {IAccountFactory} from "../interfaces/IAccountFactory.sol";
import {IDataProvider} from "../interfaces/IDataProvider.sol";

/**
 * @title Metadata contract
 * @notice A lens contract to view account information
 * @author Achthar
 */
contract AdminModule is WithStorage, IAccountMeta {
    modifier onlyOwner() {
        LibStorage.enforceAccountOwner();
        _;
    }

    function fetchAccountMetadata() external view override returns (AccountMetadata memory accountMeta) {
        accountMeta.accountName = us().accountName;
        accountMeta.accountOwner = us().accountOwner;
        accountMeta.creationTimestamp = us().creationTimestamp;
        accountMeta.accountAddress = address(this);
    }

    function renameAccount(string memory _newName) external onlyOwner {
        us().accountName = _newName;
    }

    function accountFactory() external view returns (address) {
        return gs().factory;
    }

    function previousOwner() external view returns (address) {
        return us().previousAccountOwner;
    }

    function updateDataProvider() external onlyOwner {
        ps().dataProvider = IAccountFactory(gs().factory).dataProvider();
    }
}
