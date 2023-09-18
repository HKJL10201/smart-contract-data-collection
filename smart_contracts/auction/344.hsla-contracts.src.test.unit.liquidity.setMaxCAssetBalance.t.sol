// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/liquidity/ILiquidityEvents.sol";

contract TestSetMaxCAssetBalance is Test, ILiquidityEvents, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function test_unit_setMaxCAssetBalance() public {
        vm.startPrank(owner);

        liquidity.setMaxCAssetBalance(address(cDAIToken), 100_000);

        assertEq(liquidity.maxBalanceByCAsset(address(cDAIToken)), 100_000);
    }

    function test_unit_cannot_setMaxCAssetBalance_notOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        liquidity.setMaxCAssetBalance(address(cDAIToken), 100_000);
    }
}
