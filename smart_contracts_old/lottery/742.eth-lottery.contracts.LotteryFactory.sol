//
// Copyright David Killen 2021. All rights reserved.
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Lottery.sol";


contract LotteryFactory {
    address[] public deployedLotteries;

    function createLottery(
        address payable _platformAdmin,
        address payable _lotteryOwner,
        uint64 _maxEntries,
        uint256 _entryFee,
        uint64 _lotteryFee, 
        uint64 _platformFee 

    ) public {
        address newLottery = address(new Lottery(
            _platformAdmin,
            _lotteryOwner,
            _maxEntries,
            _entryFee,
            _lotteryFee,
            _platformFee
        ));
        deployedLotteries.push(newLottery);
    }

    function getDeployedLotteries() public view returns (address[] memory) {
        return deployedLotteries;
    }
}