// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";

import "../src/compound-contracts/Comptroller.sol";
import "../src/compound-contracts/Unitroller.sol";
import "../src/compound-contracts/JumpRateModelV2.sol";
import "../src/compound-contracts/CEther.sol";

contract BxDaiDeploymentScript is Script {
    CEther bxDai;
    JumpRateModelV2 interestRateModel;

    function run() external {
        // Gnosis Addresses
        address gnosisMultisigAddress = 0xA407aD41B5703432823f3694f857097542812E5a;
        address unitroller = 0xC3D7A5884C8E3805B0221bf0b80dA45d69d5A93D;
        address interestRateModel = 0x6f4141fa4fEfb790745a5ee12d9C1Cb163550ad9;

        vm.startBroadcast();

        // deploy cTokenDelegator
        bxDai = new CEther(
            ComptrollerInterface(address(unitroller)),
            InterestRateModel(interestRateModel),
            2**18,
            "niftyApesXDai",
            "bxDai",
            8,
            payable(gnosisMultisigAddress)
        );

        // declare interfaces
        // cToken = CToken(address(bwxDai));

        // ***** IMPORTANT *****
        // gnosisMultisigAddress must call _suppoerMarket() to complete support of bxDai

        // ComptrollerInterface(address(unitroller))._supportMarket(cToken);

        vm.stopBroadcast();
    }
}
