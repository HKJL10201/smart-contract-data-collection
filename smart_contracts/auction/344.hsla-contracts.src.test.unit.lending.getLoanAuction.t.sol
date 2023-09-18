// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestGetLoanAuction is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function _test_getLoanAuction_works(FuzzedOfferFields memory fuzzed) private {
        Offer memory offerToCreate = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        (Offer memory offer, LoanAuction memory loan) = createOfferAndTryToExecuteLoanByBorrower(
            offerToCreate,
            "should work"
        );
        assertEq(loan.nftOwner, borrower1);
        assertEq(loan.lender, offer.creator);
        assertEq(loan.asset, offer.asset);
        assertEq(loan.amount, offer.amount);
        assertEq(loan.loanEndTimestamp, offer.duration + block.timestamp);
        assertEq(loan.loanBeginTimestamp, block.timestamp);
        assertEq(loan.lastUpdatedTimestamp, block.timestamp);
        assertEq(loan.amountDrawn, offer.amount);
        assertEq(loan.fixedTerms, offer.fixedTerms);
        assertEq(loan.lenderRefi, false);
        assertEq(loan.accumulatedLenderInterest, 0);
        assertEq(loan.accumulatedPaidProtocolInterest, 0);
        assertEq(loan.interestRatePerSecond, offer.interestRatePerSecond);
    }

    function test_fuzz_getLoanAuction_works(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_getLoanAuction_works(fuzzed);
    }

    function test_unit_getLoanAuction_works() public {
        _test_getLoanAuction_works(defaultFixedFuzzedFieldsForFastUnitTesting);
    }
}
