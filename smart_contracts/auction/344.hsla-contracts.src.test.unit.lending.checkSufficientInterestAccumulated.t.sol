// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestCheckSufficientInterestAccumulated is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function _test_checkSufficientInterestAccumulated_works(
        FuzzedOfferFields memory fuzzed,
        uint16 secondsBeforeRefinance
    ) private {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        (, LoanAuction memory firstLoan) = createOfferAndTryToExecuteLoanByBorrower(
            offer,
            "should work"
        );

        vm.warp(block.timestamp + secondsBeforeRefinance);

        uint256 calculatedDelta = lending.checkSufficientInterestAccumulated(
            offer.nftContractAddress,
            offer.nftId
        );

        uint256 interest = offer.interestRatePerSecond * secondsBeforeRefinance;

        uint256 threshold = (lending.gasGriefingPremiumBps() * firstLoan.amountDrawn) / MAX_BPS;

        uint256 interestDelta;

        if (threshold > interest) {
            interestDelta = threshold - interest;
        } else {
            interestDelta = 0;
        }

        assertEq(calculatedDelta, interestDelta);
    }

    function test_fuzz_checkSufficientInterestAccumulated_works(
        FuzzedOfferFields memory fuzzedOffer,
        uint16 secondsBeforeRefinance
    ) public validateFuzzedOfferFields(fuzzedOffer) {
        _test_checkSufficientInterestAccumulated_works(fuzzedOffer, secondsBeforeRefinance);
    }

    function test_unit_checkSufficientInterestAccumulated_works() public {
        uint16 secondsBeforeRefinance = 50;

        _test_checkSufficientInterestAccumulated_works(
            defaultFixedFuzzedFieldsForFastUnitTesting,
            secondsBeforeRefinance
        );
    }
}
