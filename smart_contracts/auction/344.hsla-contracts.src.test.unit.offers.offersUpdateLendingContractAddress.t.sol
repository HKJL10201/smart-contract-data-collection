// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersEvents.sol";

contract TestOffersUpdateLendingContractAddress is
    Test,
    IOffersEvents,
    OffersLoansRefinancesFixtures
{
    function setUp() public override {
        super.setUp();
    }

    function test_unit_offers_updateLendingContractAddress() public {
        vm.startPrank(owner);

        vm.expectEmit(true, true, false, false);

        emit OffersXLendingContractAddressUpdated(address(lending), address(daiToken));

        offers.updateLendingContractAddress(address(daiToken));

        assertEq(offers.lendingContractAddress(), address(daiToken));
    }

    function test_unit_offers_cannot_updateLendingContractAddress_address_is_0() public {
        vm.startPrank(owner);

        vm.expectRevert("00035");
        offers.updateLendingContractAddress(address(0));
    }

    function test_unit_offers_cannot_updateLendingContractAddress_notOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        offers.updateLendingContractAddress(address(0));
    }
}
