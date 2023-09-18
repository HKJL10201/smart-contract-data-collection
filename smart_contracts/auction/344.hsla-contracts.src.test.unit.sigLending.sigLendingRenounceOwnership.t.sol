// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";

contract TestOffersRenounceOwnership is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function test_unit_offers_renounceOwnership_does_nothing() public {
        vm.prank(owner);
        offersImplementation.renounceOwnership();

        assertEq(offersImplementation.owner(), owner);
    }
}
