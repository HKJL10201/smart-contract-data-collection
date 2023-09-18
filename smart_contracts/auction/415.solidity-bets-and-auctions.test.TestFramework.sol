// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../contracts/Betting.sol";
import "../contracts/BoxOracle.sol";
import "../contracts/Auction.sol";
import "../contracts/DutchAuction.sol";
import "../contracts/Crowdfunding.sol";
import "../contracts/EnglishAuction.sol";
import "../contracts/Timer.sol";
import "./HelperContracts.sol";
import "truffle/Assert.sol";


// Needs to be defined here or else Truffle complains
contract TestFramework{
    //can receive money
    fallback() external payable {}
}
