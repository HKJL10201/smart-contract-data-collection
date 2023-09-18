// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/liquidity/ILiquidityEvents.sol";

contract TestMustBeLendingContact is Test, ILiquidityEvents, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function test_unit_cannot_mintCErc20_notLendingContract() public {
        vm.expectRevert("00031");
        liquidity.mintCErc20(address(0), address(cDAIToken), 100_000);
    }

    function test_unit_cannot_burnCErc20_notLendingContract() public {
        vm.expectRevert("00031");
        liquidity.burnCErc20(address(cDAIToken), 100_000);
    }

    function test_unit_cannot_mintCEth_notLendingContract() public {
        vm.expectRevert("00031");
        liquidity.mintCEth{ value: 100_000 }();
    }

    function test_unit_cannot_addToCAssetBalance_notLendingContract() public {
        vm.expectRevert("00031");
        liquidity.addToCAssetBalance(address(0), address(cDAIToken), 100_000);
    }

    function test_unit_cannot_withdrawCBalance_notLendingContract() public {
        vm.expectRevert("00031");
        liquidity.withdrawCBalance(address(0), address(cDAIToken), 100_000);
    }

    function test_unit_cannot_sendValue_notLendingContract() public {
        vm.expectRevert("00031");
        liquidity.sendValue(address(cDAIToken), 100_000, address(0));
    }
}
