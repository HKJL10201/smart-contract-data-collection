// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/BaseCoinMasterWallet.sol";
import "../src/services/TransactionControlService.sol";
import "../src/services/ShieldSafetyService.sol";


contract DeployServices is Script {
    function run() external {
        vm.startBroadcast();
        TransactionControlService txService = new TransactionControlService(1000*60*60*24*3); // 3 day whitelist period
        ShieldSafetyService safetyService = new ShieldSafetyService();
        console.log("transaction service deployed:",address(txService));
        console.log("shield safety service deployed:",address(safetyService));
        vm.stopBroadcast();
    }
}