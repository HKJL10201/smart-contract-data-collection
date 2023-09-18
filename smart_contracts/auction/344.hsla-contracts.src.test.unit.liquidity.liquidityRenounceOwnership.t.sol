// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/liquidity/ILiquidityEvents.sol";

contract TestLiquidityRenounceOwnership is Test, ILiquidityEvents, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function test_unit_liquidity_renounceOwnership_does_nothing() public {
        vm.prank(owner);
        liquidityImplementation.renounceOwnership();

        assertEq(liquidityImplementation.owner(), owner);
    }
}
