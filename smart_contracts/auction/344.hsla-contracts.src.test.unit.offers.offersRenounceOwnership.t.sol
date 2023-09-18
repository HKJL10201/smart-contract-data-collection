// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";

contract TestSigLendingRenounceOwnership is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function test_unit_sigLending_renounceOwnership_does_nothing() public {
        vm.prank(owner);
        sigLendingImplementation.renounceOwnership();

        assertEq(sigLendingImplementation.owner(), owner);
    }
}
