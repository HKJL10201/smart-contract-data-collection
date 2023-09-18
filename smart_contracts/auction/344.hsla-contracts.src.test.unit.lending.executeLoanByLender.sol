// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";

contract TestExecuteLoanByLender is Test, OffersLoansRefinancesFixtures {
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
        assertEq(lending.getLoanAuction(address(mockNft), 1).lastUpdatedTimestamp, block.timestamp);
    }

    function _test_executeLoanByLender_simplest_case(FuzzedOfferFields memory fuzzed) private {
        vm.assume(fuzzed.floorTerm == false);
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedBorrowerOfferFields);
        createOfferAndTryToExecuteLoanByLender(offer, "should work");
        assertionsForExecutedLoan(offer);
    }

    function test_fuzz_executeLoanByLender_simplest_case(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_executeLoanByLender_simplest_case(fuzzed);
    }

    function test_unit_executeLoanByLender_simplest_case() public {
        FuzzedOfferFields memory fixedForSpeed = defaultFixedFuzzedFieldsForFastUnitTesting;
        _test_executeLoanByLender_simplest_case(fixedForSpeed);
    }

    function _test_executeLoanByLender_events(FuzzedOfferFields memory fuzzed) private {
        vm.assume(fuzzed.floorTerm == false);

        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedBorrowerOfferFields);

        LoanAuction memory loanAuction = lending.getLoanAuction(
            offer.nftContractAddress,
            offer.nftId
        );

        vm.expectEmit(true, true, false, false);
        emit LoanExecuted(offer.nftContractAddress, offer.nftId, loanAuction);

        createOfferAndTryToExecuteLoanByLender(offer, "should work");
    }

    function test_unit_executeLoanByLender_events() public {
        _test_executeLoanByLender_events(defaultFixedFuzzedFieldsForFastUnitTesting);
    }

    function test_fuzz_executeLoanByLender_events(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_executeLoanByLender_events(fuzzed);
    }

    function _test_cannot_executeLoanByLender_if_lender_offer(FuzzedOfferFields memory fuzzed)
        private
    {
        vm.startPrank(borrower1);
        mockNft.safeTransferFrom(borrower1, lender2, 1);
        vm.stopPrank();
        borrower1 = lender2; // we need offer creator to have a cToken balance

        defaultFixedBorrowerOfferFields.lenderOffer = true;
        defaultFixedBorrowerOfferFields.creator = lender2;
        fuzzed.floorTerm = false;

        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedBorrowerOfferFields);

        createBorrowerOffer(offer);
        approveLending(offer);
        tryToExecuteLoanByLender(offer, "00013");
    }

    function test_fuzz_executeLoanByLender_if_lender_offer(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_cannot_executeLoanByLender_if_lender_offer(fuzzed);
    }

    function test_unit_executeLoanByLender_if_lender_offer() public {
        _test_cannot_executeLoanByLender_if_lender_offer(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }
}
