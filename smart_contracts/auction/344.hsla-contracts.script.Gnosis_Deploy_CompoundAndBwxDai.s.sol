// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";

import "../src/compound-contracts/CErc20Delegate.sol";
import "../src/compound-contracts/CErc20Delegator.sol";
import "../src/compound-contracts/Comptroller.sol";
import "../src/compound-contracts/Unitroller.sol";
import "../src/compound-contracts/JumpRateModelV2.sol";
import "../src/compound-contracts/Governance/Comp.sol";

contract CompoundDeploymentScript is Script {
    CErc20Delegate cTokenImplementation;
    CErc20Delegator bwxDai;
    CToken cToken;
    Comptroller comptroller;
    Unitroller unitroller;
    JumpRateModelV2 interestRateModel;
    Comp bComp;

    function run() external {
        // Gnosis Addresses
        address gnosisMultisigAddress = 0xA407aD41B5703432823f3694f857097542812E5a;
        address wxDai = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;

        vm.startBroadcast();

        bComp = new Comp(gnosisMultisigAddress);
        comptroller = new Comptroller(address(bComp));
        unitroller = new Unitroller();
        interestRateModel = new JumpRateModelV2(1, 1, 1, 100, gnosisMultisigAddress);

        unitroller._setPendingImplementation(address(comptroller));

        comptroller._become(unitroller);
        ComptrollerInterface(address(unitroller))._setSeizePaused(true);
        ComptrollerInterface(address(unitroller))._setBCompAddress(address(bComp));

        // deploy and initialize implementation contracts
        cTokenImplementation = new CErc20Delegate();

        // deploy cTokenDelegator
        bwxDai = new CErc20Delegator(
            address(wxDai),
            ComptrollerInterface(address(unitroller)),
            interestRateModel,
            2**18,
            "niftyApesWrappedXDai",
            "bwxDai",
            8,
            payable(gnosisMultisigAddress),
            address(cTokenImplementation),
            bytes("")
        );

        // declare interfaces
        cToken = CToken(address(bwxDai));

        ComptrollerInterface(address(unitroller))._supportMarket(cToken);
        ComptrollerInterface(address(unitroller))._setBorrowPaused(cToken, true);
        unitroller._setPendingAdmin(gnosisMultisigAddress);

        // ***** IMPORTANT *****
        // gnosisMultisigAddress must call _acceptAdmin() to complete ownership transfer for unitroller

        vm.stopBroadcast();
    }
}
