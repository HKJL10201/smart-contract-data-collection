// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/liquidity/ILiquidityEvents.sol";

contract TestUpdateRegenCollectiveAddress is Test, ILiquidityEvents, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function test_unit_updateRegenCollectiveAddress() public {
        vm.startPrank(owner);

        vm.expectEmit(true, false, false, false);

        emit RegenCollectiveAddressUpdated(address(0));

        liquidity.updateRegenCollectiveAddress(address(0));

        assertEq(liquidity.regenCollectiveAddress(), address(0));
    }

    function test_unit_cannot_updateRegenCollectiveAddress_notOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        liquidity.updateRegenCollectiveAddress(address(0));
    }
}
