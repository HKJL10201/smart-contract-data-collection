// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestLendingRenounceOwnership is Test, ILendingEvents, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function test_unit_lending_renounceOwnership_does_nothing() public {
        vm.prank(owner);
        lendingImplementation.renounceOwnership();

        assertEq(lendingImplementation.owner(), owner);
    }
}
