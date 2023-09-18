// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersEvents.sol";

contract TestOffersUpdateSigLendingContractAddress is
    Test,
    IOffersEvents,
    OffersLoansRefinancesFixtures
{
    function setUp() public override {
        super.setUp();
    }

    function test_unit_offers_updateSigLendingContractAddress() public {
        vm.startPrank(owner);

        vm.expectEmit(true, true, false, false);

        emit OffersXSigLendingContractAddressUpdated(address(lending), address(daiToken));

        offers.updateSigLendingContractAddress(address(daiToken));

        assertEq(offers.sigLendingContractAddress(), address(daiToken));
    }

    function test_unit_offers_cannot_updateSigLendingContractAddress_address_is_0() public {
        vm.startPrank(owner);

        vm.expectRevert("00035");
        offers.updateSigLendingContractAddress(address(0));
    }

    function test_unit_offers_cannot_updateSigLendingContractAddress_notOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        offers.updateSigLendingContractAddress(address(0));
    }
}
