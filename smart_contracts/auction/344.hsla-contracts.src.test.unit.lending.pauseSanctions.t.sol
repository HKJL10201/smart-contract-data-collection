// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestLendingPauseSanctions is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function test_fuzz_lending_pauseSanctions_works(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        vm.prank(owner);
        lending.pauseSanctions();

        vm.startPrank(lender1);
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        offer.nftId = 3;
        bytes32 offerHash = offers.createOffer(offer);
        vm.stopPrank();

        vm.startPrank(SANCTIONED_ADDRESS);
        mockNft.approve(address(lending), offer.nftId);
        offers.getOfferHash(offer);
        lending.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function test_unit_lending_cannot_pauseSanctions_notOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        lending.pauseSanctions();
    }

    function test_fuzz_lending_unpauseSanctions_works(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        vm.prank(owner);
        lending.pauseSanctions();

        vm.startPrank(lender1);
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        offer.nftId = 3;
        bytes32 offerHash = offers.createOffer(offer);
        vm.stopPrank();

        vm.startPrank(SANCTIONED_ADDRESS);
        mockNft.approve(address(lending), offer.nftId);
        offers.getOfferHash(offer);

        lending.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
        vm.stopPrank();

        vm.prank(owner);
        lending.unpauseSanctions();

        vm.startPrank(SANCTIONED_ADDRESS);
        vm.expectRevert("00017");
        lending.repayLoan(offer.nftContractAddress, offer.nftId);
    }

    function test_unit_lending_cannot_unpauseSanctions_notOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        lending.unpauseSanctions();
    }
}
