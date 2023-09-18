// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/BaseCoinMasterWallet.sol";
import "../src/services/TransactionControlService.sol";
import "../src/services/ShieldSafetyService.sol";


contract DeployTest is Test {
    BaseCoinMasterWallet public wallet;
    TransactionControlService public txService;
    ShieldSafetyService public safetyService;


    function setUp() public {
        txService = new TransactionControlService(1000*60*60*24*3); // 3 day whitelist period
        safetyService = new ShieldSafetyService();
        address[] memory services = new address[](2);
        services[0] = address(txService);
        services[1] = address(safetyService);
        wallet = new BaseCoinMasterWallet(services, "testName");
    }

    function testSetup() public {
        assertTrue(address(wallet) != address(0));
        assertTrue(address(txService) != address(0));
        assertTrue(address(safetyService) != address(0));
    }
}