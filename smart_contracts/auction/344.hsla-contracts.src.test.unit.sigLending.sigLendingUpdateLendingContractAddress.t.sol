// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/sigLending/ISigLendingEvents.sol";

contract TestSigLendingUpdateLendingContractAddress is
    Test,
    ISigLendingEvents,
    OffersLoansRefinancesFixtures
{
    function setUp() public override {
        super.setUp();
    }

    function test_unit_sigLending_updateLendingContractAddress() public {
        vm.startPrank(owner);

        vm.expectEmit(true, true, false, false);

        emit SigLendingXLendingContractAddressUpdated(address(lending), address(0));

        sigLending.updateLendingContractAddress(address(0));

        assertEq(sigLending.lendingContractAddress(), address(0));
    }

    function test_unit_cannot_updateLendingContractAddress_notOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        sigLending.updateLendingContractAddress(address(0));
    }
}
