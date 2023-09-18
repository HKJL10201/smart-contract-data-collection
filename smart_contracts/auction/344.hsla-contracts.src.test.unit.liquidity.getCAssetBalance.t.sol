// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/liquidity/ILiquidityEvents.sol";

contract TestGetCAssetBalance is Test, ILiquidityEvents, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function test_unit_getCAssetBalance_starts_at_zero() public {
        assertEq(
            liquidity.getCAssetBalance(
                address(0x0000000000000000000000000000000000000001),
                address(0x0000000000000000000000000000000000000002)
            ),
            0
        );
    }

    function test_unit_getCAssetBalance_works() public {
        if (!integration) {
            assertEq(
                liquidity.getCAssetBalance(address(lender1), address(cDAIToken)),
                2000000000000000000000000000000000000000
            );
        }
    }
}
