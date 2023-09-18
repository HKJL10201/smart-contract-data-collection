// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../../../compound-contracts/CTokenInterfaces.sol";
import "../../../compound-contracts/CErc20Delegate.sol";
import "../../../compound-contracts/CErc20Delegator.sol";
import "../../../compound-contracts/Comptroller.sol";
import "../../../compound-contracts/Unitroller.sol";
import "../../../compound-contracts/JumpRateModelV2.sol";
import "../../../compound-contracts/Governance/Comp.sol";
import "../../../compound-contracts/CEther.sol";

import "../../mock/CERC20Mock.sol";
import "../../mock/CEtherMock.sol";

import "./NiftyApesDeployment.sol";

import "forge-std/Test.sol";

// deploy & initializes bCompound Contracts
contract CompoundDeployment is Test, NiftyApesDeployment {
    CErc20Delegate cTokenImplementation;
    CErc20Delegator bDAI;
    CEther bETH;
    CToken cToken;
    CToken cEther;
    Comptroller comptroller;
    Unitroller unitroller;
    JumpRateModelV2 interestRateModel;
    Comp bComp;

    bool internal BDAI = false;

    function setUp() public virtual override {
        super.setUp();

        try vm.envBool("BDAI") returns (bool isBDai) {
            BDAI = isBDai;
        } catch (bytes memory) {
            // This catches revert that occurs if env variable not supplied
        }

        vm.startPrank(owner);

        bComp = new Comp(owner);
        comptroller = new Comptroller(address(bComp));
        unitroller = new Unitroller();
        interestRateModel = new JumpRateModelV2(1, 1, 1, 100, owner);

        unitroller._setPendingImplementation(address(comptroller));

        comptroller._become(unitroller);
        ComptrollerInterface(address(unitroller))._setSeizePaused(true);
        ComptrollerInterface(address(unitroller))._setBCompAddress(address(bComp));

        // deploy and initialize implementation contracts
        cTokenImplementation = new CErc20Delegate();

        // deploy cTokenDelegator
        bDAI = new CErc20Delegator(
            address(daiToken),
            ComptrollerInterface(address(unitroller)),
            interestRateModel,
            2**18,
            "niftyApesWrappedXDai",
            "bwxDai",
            8,
            owner,
            address(cTokenImplementation),
            bytes("")
        );

        // deploy cETH
        bETH = new CEther(
            ComptrollerInterface(address(unitroller)),
            interestRateModel,
            2**18,
            "niftyApesXDai",
            "bxDai",
            8,
            owner
        );

        // declare interfaces
        cToken = CToken(address(bDAI));
        cEther = CToken(address(bETH));

        ComptrollerInterface(address(unitroller))._supportMarket(cToken);
        ComptrollerInterface(address(unitroller))._supportMarket(cToken);
        ComptrollerInterface(address(unitroller))._setBorrowPaused(cToken, true);

        if (BDAI) {
            cDAIToken = CERC20Mock(address(bDAI));
            liquidity.setCAssetAddress(address(daiToken), address(cDAIToken));
            liquidity.setMaxCAssetBalance(address(cDAIToken), ~uint256(0));

            cEtherToken = CEtherMock(address(bETH));
            liquidity.setCAssetAddress(address(ETH_ADDRESS), address(cEtherToken));
            liquidity.setMaxCAssetBalance(address(cEtherToken), ~uint256(0));
        }

        vm.stopPrank();

        vm.label(address(0), "NULL !!!!! ");
    }
}
