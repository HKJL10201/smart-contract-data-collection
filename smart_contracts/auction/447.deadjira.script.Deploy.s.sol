// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { DeadjiraAuction } from "../src/Deadjira.sol";

import { BaseScript } from "./Base.s.sol";

contract Deploy is BaseScript {
    function run() public broadcaster returns (DeadjiraAuction auction) {
        auction = new DeadjiraAuction();
    }
}
