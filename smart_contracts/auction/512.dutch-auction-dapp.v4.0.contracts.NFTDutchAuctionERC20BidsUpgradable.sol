//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./DutchAuctionNFT_ERC20Bids.sol";

contract NFTDutchAuctionERC20BidsUpgradable is NFTDutchAuction_ERC20Bids {
    function currentVersion() public pure returns (uint) {
        return 2;
    }
}
