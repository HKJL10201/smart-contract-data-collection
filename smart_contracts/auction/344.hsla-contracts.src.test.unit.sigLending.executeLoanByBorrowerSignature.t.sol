// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersEvents.sol";

contract TestExecuteLoanByBorrowerSignature is Test, OffersLoansRefinancesFixtures, IOffersEvents {
    function setUp() public override {
        super.setUp();
    }

    function assertionsForExecutedLoan(Offer memory offer) private {
        // borrower has money
        if (offer.asset == address(daiToken)) {
            assertEq(daiToken.balanceOf(borrower1), offer.amount);
        } else {
            assertEq(borrower1.balance, defaultInitialEthBalance + offer.amount);
        }
        // lending contract has NFT
        assertEq(mockNft.ownerOf(1), address(lending));
        // loan auction exists
        assertEq(
            lending.getLoanAuction(offer.nftContractAddress, offer.nftId).lastUpdatedTimestamp,
            block.timestamp
        );
    }

    function _test_executeLoanByBorrowerSignature_simplest_case(FuzzedOfferFields memory fuzzed)
        private
    {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        bytes memory signature = signOffer(lender1_private_key, offer);

        vm.startPrank(borrower1);
        mockNft.approve(address(lending), offer.nftId);
        sigLending.executeLoanByBorrowerSignature(offer, signature, 1);
        vm.stopPrank();

        assertionsForExecutedLoan(offer);
    }

    function test_fuzz_executeLoanByBorrowerSignature_simplest_case(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_executeLoanByBorrowerSignature_simplest_case(fuzzed);
    }

    function test_unit_executeLoanByBorrowerSignature_simplest_case() public {
        FuzzedOfferFields memory fixedForSpeed = defaultFixedFuzzedFieldsForFastUnitTesting;
        _test_executeLoanByBorrowerSignature_simplest_case(fixedForSpeed);
    }

    function _test_executeLoanByBorrowerSignature_emits_loan_executed(
        FuzzedOfferFields memory fuzzed
    ) private {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        bytes memory signature = signOffer(lender1_private_key, offer);

        vm.startPrank(borrower1);
        mockNft.approve(address(lending), offer.nftId);

        LoanAuction memory loanAuction = lending.getLoanAuction(
            offer.nftContractAddress,
            offer.nftId
        );

        hevm.expectEmit(true, false, false, false);

        emit LoanExecuted(offer.nftContractAddress, offer.nftId, loanAuction);

        sigLending.executeLoanByBorrowerSignature(offer, signature, 1);
        vm.stopPrank();

        assertionsForExecutedLoan(offer);
    }

    function test_fuzz_executeLoanByBorrowerSignature_emits_loan_executed(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_executeLoanByBorrowerSignature_emits_loan_executed(fuzzed);
    }

    function test_unit_executeLoanByBorrowerSignature_emits_loan_executed() public {
        FuzzedOfferFields memory fixedForSpeed = defaultFixedFuzzedFieldsForFastUnitTesting;
        _test_executeLoanByBorrowerSignature_simplest_case(fixedForSpeed);
    }

    // FYI old tests were looking for AmountDrawn event
    // but this no longer appears to be emitted during executeLoanByBorrowerSignature

    function _test_executeLoanByBorrowerSignature_emits_offer_signature_used(
        FuzzedOfferFields memory fuzzed
    ) private {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        bytes memory signature = signOffer(lender1_private_key, offer);

        vm.startPrank(borrower1);
        mockNft.approve(address(lending), offer.nftId);

        vm.expectEmit(true, true, false, true); // OfferSignatureUsed has two indexes
        emit OfferSignatureUsed(offer.nftContractAddress, offer.nftId, offer, signature);

        sigLending.executeLoanByBorrowerSignature(offer, signature, offer.nftId);
        vm.stopPrank();

        assertionsForExecutedLoan(offer);
    }

    function test_fuzz_executeLoanByBorrowerSignature_emits_offer_signature_used(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        fuzzed.floorTerm = false;
        _test_executeLoanByBorrowerSignature_emits_offer_signature_used(fuzzed);
    }

    function test_unit_executeLoanByBorrowerSignature_emits_offer_signature_used() public {
        FuzzedOfferFields memory fixedForSpeed = defaultFixedFuzzedFieldsForFastUnitTesting;
        _test_executeLoanByBorrowerSignature_emits_offer_signature_used(fixedForSpeed);
    }
}
