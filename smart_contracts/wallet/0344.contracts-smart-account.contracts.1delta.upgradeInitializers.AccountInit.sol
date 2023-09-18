// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibStorage, WithStorage, GeneralStorage, UserAccountStorage, DataProviderStorage} from "../libraries/LibStorage.sol";
import {IAccountInit} from "../interfaces/IAccountInit.sol";
import {IDataProvider} from "../interfaces/IDataProvider.sol";
import {TokenTransfer} from "../libraries/TokenTransfer.sol";

// Initialies 1Delta user accounts
// A name can be picked and all relevant underlyings can be set up in the lending protocol if the correct
// flag is set.
contract AccountInit is WithStorage, IAccountInit, TokenTransfer {
    /**
     * @notice The initializer only initializes the module provider, data provider and owner
     * @param _dataProvider Data provider contract
     * @param _owner The owner of the account
     * @param _enterAndApprove If true, all compound markets are entered and spending on cTokens enabled
     */
    function init(
        address _dataProvider,
        address _owner,
        string memory _name,
        bool _enterAndApprove
    ) external override {
        require(!gs().initialized, "Alrady initialized");
        gs().initialized = true;
        UserAccountStorage storage us = LibStorage.userAccountStorage();
        us.accountOwner = _owner;
        us.accountName = _name;
        us.creationTimestamp = block.timestamp;

        address dataProvider = _dataProvider;
        DataProviderStorage storage ps = LibStorage.dataProviderStorage();
        ps.dataProvider = dataProvider;

        if (_enterAndApprove) {
            enterMarketsOnInit(IDataProvider(dataProvider).allCTokens());
            approveUnderlyingsOnInit(IDataProvider(dataProvider).allUnderlyings());
        }
    }

    function approveUnderlyingsOnInit(address[] memory _underlyings) private {
        for (uint256 i = 0; i < _underlyings.length; i++) {
            address _underlying = _underlyings[i];
            address _cToken = address(IDataProvider(ps().dataProvider).cToken(_underlying));
            _approve(_underlying, _cToken, type(uint256).max);
        }
    }

    function enterMarketsOnInit(address[] memory cTokens) private {
        IDataProvider(ps().dataProvider).getComptroller().enterMarkets(cTokens);
    }
}
