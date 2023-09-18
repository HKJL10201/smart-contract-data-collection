// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestCheckSufficientTerms is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function _test_checkSufficientTerms_works(
        FuzzedOfferFields memory fuzzed,
        uint128 amount,
        uint96 interestRatePerSecond,
        uint32 duration
    ) private {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        (, LoanAuction memory firstLoan) = createOfferAndTryToExecuteLoanByBorrower(
            offer,
            "should work"
        );

        vm.assume(amount >= firstLoan.amount);
        vm.assume(duration >= firstLoan.loanEndTimestamp - firstLoan.loanBeginTimestamp);
        vm.assume(interestRatePerSecond <= firstLoan.interestRatePerSecond);

        bool calculatedSufficientTerms = lending.checkSufficientTerms(
            offer.nftContractAddress,
            offer.nftId,
            amount,
            interestRatePerSecond,
            duration
        );

        uint256 loanDuration = firstLoan.loanEndTimestamp - firstLoan.loanBeginTimestamp;

        // calculate the Bps improvement of each offer term
        uint256 amountImprovement = ((amount - firstLoan.amount) * MAX_BPS) / firstLoan.amount;

        uint256 interestImprovement = ((firstLoan.interestRatePerSecond - interestRatePerSecond) *
            MAX_BPS) / firstLoan.interestRatePerSecond;

        uint256 durationImprovement = ((duration - loanDuration) * MAX_BPS) / loanDuration;

        // sum improvements
        uint256 improvementSum = amountImprovement + interestImprovement + durationImprovement;

        // check and return if improvements are greater than 25 bps total
        bool sufficientTermsResult = improvementSum > lending.termGriefingPremiumBps();

        assertEq(calculatedSufficientTerms, sufficientTermsResult);
    }

    function test_fuzz_checkSufficientTerms_works(
        FuzzedOfferFields memory fuzzed,
        uint128 amount,
        uint96 interestRatePerSecond,
        uint32 duration
    ) public {
        // -10 ether to give refinancing lender some wiggle room for fees
        if (fuzzed.randomAsset % 2 == 0) {
            vm.assume(fuzzed.amount > 0);
            vm.assume(fuzzed.amount < (defaultDaiLiquiditySupplied * 90) / 100);
        } else {
            vm.assume(fuzzed.amount > 0);
            vm.assume(fuzzed.amount < (defaultEthLiquiditySupplied * 90) / 100);
        }

        vm.assume(fuzzed.duration > 1 days);
        // to avoid overflow when loanAuction.loanEndTimestamp = _currentTimestamp32() + offer.duration;
        vm.assume(fuzzed.duration < ~uint32(0) - block.timestamp);
        vm.assume(fuzzed.expiration > block.timestamp);
        // to avoid "Division or modulo by 0"
        vm.assume(fuzzed.interestRatePerSecond > 0);

        _test_checkSufficientTerms_works(fuzzed, amount, interestRatePerSecond, duration);
    }

    function test_unit_checkSufficientTerms_works() public {
        uint128 amount = 10 ether;
        uint96 interestRatePerSecond = 5;
        uint32 duration = 1 weeks;

        _test_checkSufficientTerms_works(
            defaultFixedFuzzedFieldsForFastUnitTesting,
            amount,
            interestRatePerSecond,
            duration
        );
    }
}
