// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestCalculateInterestAccrued is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function _test_calculateInterestAccrued_works(
        FuzzedOfferFields memory fuzzed,
        uint16 secondsBeforeRefinance
    ) private {
        vm.startPrank(owner);
        lending.updateProtocolInterestBps(100);
        vm.stopPrank();

        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        (, LoanAuction memory firstLoan) = createOfferAndTryToExecuteLoanByBorrower(
            offer,
            "should work"
        );

        // new offer from lender2 with +1 amount
        // will trigger term griefing and gas griefing
        defaultFixedOfferFields.creator = lender2;
        fuzzed.duration = fuzzed.duration + 1; // make sure offer is better
        fuzzed.floorTerm = false; // refinance can't be floor term
        fuzzed.expiration = uint32(block.timestamp) + secondsBeforeRefinance + 1;
        Offer memory newOffer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        vm.warp(block.timestamp + secondsBeforeRefinance);

        (uint256 lenderInterest, uint256 protocolInterest) = lending.calculateInterestAccrued(
            newOffer.nftContractAddress,
            newOffer.nftId
        );

        LoanAuction memory secondLoan = tryToRefinanceByLender(newOffer, "should work");

        uint256 expectedLenderInterest = firstLoan.interestRatePerSecond * secondsBeforeRefinance;
        uint256 expectedProtocolInterest = firstLoan.protocolInterestRatePerSecond *
            secondsBeforeRefinance;

        assertEq(lenderInterest, expectedLenderInterest);
        assertEq(protocolInterest, expectedProtocolInterest);
        assertEq(secondLoan.accumulatedLenderInterest, expectedLenderInterest);
        assertEq(secondLoan.accumulatedPaidProtocolInterest, expectedProtocolInterest);
    }

    function test_fuzz_calculateInterestAccrued_works(
        FuzzedOfferFields memory fuzzed,
        uint16 secondsBeforeRefinance
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_calculateInterestAccrued_works(fuzzed, secondsBeforeRefinance);
    }

    function test_unit_calculateInterestAccrued_works() public {
        uint16 secondsBeforeRefinance = 100;

        _test_calculateInterestAccrued_works(
            defaultFixedFuzzedFieldsForFastUnitTesting,
            secondsBeforeRefinance
        );
    }
}
