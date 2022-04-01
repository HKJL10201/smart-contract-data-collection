//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract VestingWalletFactory {
    event VestingWalletCreated(address indexed beneficiaryAddress, address indexed wallet);

    address[] public wallets;

    function create(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) public returns (address wallet) {
        wallet = address(new VestingWallet(beneficiaryAddress, startTimestamp, durationSeconds));
        wallets.push(wallet);
        emit VestingWalletCreated(beneficiaryAddress, wallet);
    }
}
