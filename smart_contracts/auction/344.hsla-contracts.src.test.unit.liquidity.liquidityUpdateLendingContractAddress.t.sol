// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/liquidity/ILiquidityEvents.sol";

contract TestLiquidityUpdateLendingContractAddress is
    Test,
    ILiquidityEvents,
    OffersLoansRefinancesFixtures
{
    function setUp() public override {
        super.setUp();
    }

    function test_unit_updateLendingContractAddress() public {
        vm.startPrank(owner);

        vm.expectEmit(true, true, false, false);

        emit LiquidityXLendingContractAddressUpdated(address(lending), address(0));

        liquidity.updateLendingContractAddress(address(0));

        assertEq(liquidity.lendingContractAddress(), address(0));
    }

    function test_unit_cannot_updateLendingContractAddress_notOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        liquidity.updateLendingContractAddress(address(0));
    }
}
