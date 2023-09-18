// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";

contract TestDrawLoanAmount is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    // this is set up to have the borrower refinance
    // there's no reason to prefer borrower to lender here
    // or vice versa
    function refinanceSetup(
        FuzzedOfferFields memory fuzzed,
        uint16 secondsBeforeRefinance,
        uint256 amountExtraOnRefinance
    ) private {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        // values for unit test
        // offer.amount = 8640000;
        // offer.duration = 1 days;
        // offer.interestRatePerSecond = 1;

        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");

        assertionsForExecutedLoan(offer);

        LoanAuction memory loanAuction = lending.getLoanAuction(
            offer.nftContractAddress,
            offer.nftId
        );

        vm.warp(block.timestamp + secondsBeforeRefinance);

        uint256 interestShortfall = lending.checkSufficientInterestAccumulated(
            offer.nftContractAddress,
            offer.nftId
        );

        (, uint256 protocolInterest) = lending.calculateInterestAccrued(
            offer.nftContractAddress,
            offer.nftId
        );

        // will trigger gas griefing (but not term griefing with borrower refinance)
        defaultFixedOfferFields.creator = lender2;
        fuzzed.floorTerm = false; // refinance can't be floor term
        fuzzed.expiration = uint32(block.timestamp) + secondsBeforeRefinance + 1;
        fuzzed.amount = uint128(
            offer.amount +
                ((loanAuction.amountDrawn * lending.originationPremiumBps()) / MAX_BPS) +
                (offer.interestRatePerSecond * secondsBeforeRefinance) +
                interestShortfall +
                protocolInterest +
                amountExtraOnRefinance
        );

        Offer memory newOffer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        // values for unit test
        // newOffer.amount = uint128(
        //     offer.amount +
        //         ((loanAuction.amountDrawn * lending.originationPremiumBps()) / MAX_BPS) +
        //         (offer.interestRatePerSecond * secondsBeforeRefinance) +
        //         interestShortfall +
        //         protocolInterest +
        //         amountExtraOnRefinance
        // );
        // newOffer.duration = 1 days;
        // newOffer.interestRatePerSecond = 1;

        uint256 beforeRefinanceLenderBalance = assetBalance(lender1, address(daiToken));

        if (offer.asset == address(daiToken)) {
            beforeRefinanceLenderBalance = assetBalance(lender1, address(daiToken));
        } else {
            beforeRefinanceLenderBalance = assetBalance(lender1, ETH_ADDRESS);
        }

        tryToRefinanceLoanByBorrower(newOffer, "should work");

        assertionsForExecutedRefinance(
            offer,
            loanAuction.amountDrawn,
            lending.originationPremiumBps(),
            secondsBeforeRefinance,
            interestShortfall,
            beforeRefinanceLenderBalance
        );
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

    function assertionsForExecutedRefinance(
        Offer memory offer,
        uint256 amountDrawn,
        uint256 originationPremium,
        uint16 secondsBeforeRefinance,
        uint256 interestShortfall,
        uint256 beforeRefinanceLenderBalance
    ) private {
        // lender1 has money
        if (offer.asset == address(daiToken)) {
            assertBetween(
                beforeRefinanceLenderBalance +
                    amountDrawn +
                    ((amountDrawn * originationPremium) / MAX_BPS) +
                    (offer.interestRatePerSecond * secondsBeforeRefinance) +
                    interestShortfall,
                assetBalance(lender1, address(daiToken)),
                assetBalancePlusOneCToken(lender1, address(daiToken))
            );
        } else {
            assertBetween(
                beforeRefinanceLenderBalance +
                    amountDrawn +
                    ((amountDrawn * originationPremium) / MAX_BPS) +
                    (offer.interestRatePerSecond * secondsBeforeRefinance) +
                    interestShortfall,
                assetBalance(lender1, ETH_ADDRESS),
                assetBalancePlusOneCToken(lender1, ETH_ADDRESS)
            );
        }
    }

    function test_fuzz_drawLoanAmount_simplest_case(
        FuzzedOfferFields memory fuzzedOffer,
        uint16 secondsBeforeRefinance,
        uint64 amountExtraOnRefinance,
        bool excessDraw
    ) public validateFuzzedOfferFields(fuzzedOffer) {
        vm.assume(amountExtraOnRefinance > 0);
        // since we add 1 to amountExtraOnRefinance sometimes below
        // we want to make sure adding 1 doesn't overflow
        vm.assume(amountExtraOnRefinance < ~uint64(0));
        if (fuzzedOffer.randomAsset % 2 == 0) {
            vm.assume(amountExtraOnRefinance < (defaultDaiLiquiditySupplied * 2) / 100);
        } else {
            vm.assume(amountExtraOnRefinance < (defaultEthLiquiditySupplied * 2) / 100);
        }

        bool isRefinanceExtraEnough; // to avoid "redeemTokens zero" when borrower draws more
        if (fuzzedOffer.randomAsset % 2 == 0) {
            isRefinanceExtraEnough =
                amountExtraOnRefinance >= 10 * uint128(10**daiToken.decimals());
        } else {
            isRefinanceExtraEnough = amountExtraOnRefinance >= 250000000;
        }

        amountExtraOnRefinance = isRefinanceExtraEnough
            ? amountExtraOnRefinance
            : uint64(
                fuzzedOffer.randomAsset % 2 == 0 ? 10 * uint128(10**daiToken.decimals()) : 250000000
            );

        refinanceSetup(fuzzedOffer, secondsBeforeRefinance, amountExtraOnRefinance);

        vm.startPrank(borrower1);
        if (excessDraw) {
            vm.expectRevert("00020");
        }

        lending.drawLoanAmount(
            defaultFixedOfferFields.nftContractAddress,
            defaultFixedOfferFields.nftId,
            excessDraw ? amountExtraOnRefinance + 1 : amountExtraOnRefinance
        );
        vm.stopPrank();
    }

    function test_fuzz_drawLoanAmount_math_works(
        FuzzedOfferFields memory fuzzedOffer,
        uint16 secondsBeforeRefinance,
        uint64 amountExtraOnRefinance
    ) public validateFuzzedOfferFields(fuzzedOffer) {
        vm.startPrank(owner);
        lending.updateProtocolInterestBps(100);
        vm.stopPrank();

        vm.assume(amountExtraOnRefinance > 0);
        // since we add 1 to amountExtraOnRefinance sometimes below
        // we want to make sure adding 1 doesn't overflow
        vm.assume(amountExtraOnRefinance < ~uint64(0));
        if (fuzzedOffer.randomAsset % 2 == 0) {
            vm.assume(amountExtraOnRefinance < (defaultDaiLiquiditySupplied * 2) / 100);
        } else {
            vm.assume(amountExtraOnRefinance < (defaultEthLiquiditySupplied * 2) / 100);
        }

        bool isRefinanceExtraEnough; // to avoid "redeemTokens zero" when borrower draws more
        if (fuzzedOffer.randomAsset % 2 == 0) {
            isRefinanceExtraEnough =
                amountExtraOnRefinance >= 10 * uint128(10**daiToken.decimals());
        } else {
            isRefinanceExtraEnough = amountExtraOnRefinance >= 250000000;
        }

        amountExtraOnRefinance = isRefinanceExtraEnough
            ? amountExtraOnRefinance
            : uint64(
                fuzzedOffer.randomAsset % 2 == 0 ? 10 * uint128(10**daiToken.decimals()) : 250000000
            );

        refinanceSetup(fuzzedOffer, secondsBeforeRefinance, amountExtraOnRefinance);

        LoanAuction memory loanAuctionBefore = lending.getLoanAuction(
            defaultFixedOfferFields.nftContractAddress,
            defaultFixedOfferFields.nftId
        );

        uint256 amountDrawnBefore = loanAuctionBefore.amountDrawn;

        uint256 interestRatePerSecondBefore = loanAuctionBefore.interestRatePerSecond;

        vm.startPrank(borrower1);
        lending.drawLoanAmount(
            defaultFixedOfferFields.nftContractAddress,
            defaultFixedOfferFields.nftId,
            amountExtraOnRefinance
        );
        vm.stopPrank();

        LoanAuction memory loanAuctionAfter = lending.getLoanAuction(
            defaultFixedOfferFields.nftContractAddress,
            defaultFixedOfferFields.nftId
        );

        uint256 interestRatePerSecondAfter = loanAuctionAfter.interestRatePerSecond;
        uint256 protocolInterestRatePerSecondAfter = loanAuctionAfter.protocolInterestRatePerSecond;

        uint256 interestBps = (((interestRatePerSecondBefore *
            (loanAuctionAfter.loanEndTimestamp - loanAuctionAfter.loanBeginTimestamp)) * MAX_BPS) /
            loanAuctionBefore.amountDrawn) + 1;

        uint256 calculatedInterestRatePerSecond = ((loanAuctionAfter.amountDrawn * interestBps) /
            MAX_BPS /
            (loanAuctionAfter.loanEndTimestamp - loanAuctionAfter.loanBeginTimestamp));
        if (calculatedInterestRatePerSecond == 0 && interestBps != 0) {
            calculatedInterestRatePerSecond = 1;
        }
        uint96 calculatedProtocolInterestRatePerSecond = lending.calculateInterestPerSecond(
            loanAuctionAfter.amountDrawn,
            lending.protocolInterestBps(),
            (loanAuctionAfter.loanEndTimestamp - loanAuctionAfter.loanBeginTimestamp)
        );

        // lenderRefi is false
        assertFalse(lending.getLoanAuction(address(mockNft), 1).lenderRefi);

        assertEq(calculatedInterestRatePerSecond, interestRatePerSecondAfter);
        assertEq(calculatedProtocolInterestRatePerSecond, protocolInterestRatePerSecondAfter);
        assertEq(loanAuctionAfter.amountDrawn, amountDrawnBefore + amountExtraOnRefinance);
    }

    function test_unit_drawLoanAmount_math_works() public {
        uint16 secondsBeforeRefinance = 100;
        uint256 amountExtraOnRefinance = 864000000;

        // specify particular amount and duration in refinanceSetup below offer creation.
        // values are reset upon initial offer creation.

        vm.startPrank(owner);
        lending.updateProtocolInterestBps(1);
        vm.stopPrank();

        bool isRefinanceExtraEnough; // to avoid "redeemTokens zero" when borrower draws more
        if (defaultFixedFuzzedFieldsForFastUnitTesting.randomAsset % 2 == 0) {
            isRefinanceExtraEnough =
                amountExtraOnRefinance >= 10 * uint128(10**daiToken.decimals());
        } else {
            isRefinanceExtraEnough = amountExtraOnRefinance >= 250000000;
        }

        amountExtraOnRefinance = isRefinanceExtraEnough
            ? amountExtraOnRefinance
            : uint256(
                defaultFixedFuzzedFieldsForFastUnitTesting.randomAsset % 2 == 0
                    ? 10 * uint128(10**daiToken.decimals())
                    : 250000000
            );

        refinanceSetup(
            defaultFixedFuzzedFieldsForFastUnitTesting,
            secondsBeforeRefinance,
            amountExtraOnRefinance
        );

        LoanAuction memory loanAuctionBefore = lending.getLoanAuction(
            defaultFixedOfferFields.nftContractAddress,
            defaultFixedOfferFields.nftId
        );

        uint256 amountDrawnBefore = loanAuctionBefore.amountDrawn;

        uint256 interestRatePerSecondBefore = loanAuctionBefore.interestRatePerSecond;

        vm.startPrank(borrower1);
        lending.drawLoanAmount(
            defaultFixedOfferFields.nftContractAddress,
            defaultFixedOfferFields.nftId,
            amountExtraOnRefinance
        );
        vm.stopPrank();

        LoanAuction memory loanAuctionAfter = lending.getLoanAuction(
            defaultFixedOfferFields.nftContractAddress,
            defaultFixedOfferFields.nftId
        );

        uint256 interestRatePerSecondAfter = loanAuctionAfter.interestRatePerSecond;
        uint256 protocolInterestRatePerSecondAfter = loanAuctionAfter.protocolInterestRatePerSecond;

        uint256 interestBps = (((interestRatePerSecondBefore *
            (loanAuctionAfter.loanEndTimestamp - loanAuctionAfter.loanBeginTimestamp)) * MAX_BPS) /
            loanAuctionBefore.amountDrawn) + 1;

        uint256 calculatedInterestRatePerSecond = ((loanAuctionAfter.amountDrawn * interestBps) /
            MAX_BPS /
            (loanAuctionAfter.loanEndTimestamp - loanAuctionAfter.loanBeginTimestamp));
        if (calculatedInterestRatePerSecond == 0 && interestBps != 0) {
            calculatedInterestRatePerSecond = 1;
        }
        uint96 calculatedProtocolInterestRatePerSecond = lending.calculateInterestPerSecond(
            loanAuctionAfter.amountDrawn,
            lending.protocolInterestBps(),
            (loanAuctionAfter.loanEndTimestamp - loanAuctionAfter.loanBeginTimestamp)
        );

        // lenderRefi is false
        assertFalse(lending.getLoanAuction(address(mockNft), 1).lenderRefi);

        assertEq(calculatedInterestRatePerSecond, interestRatePerSecondAfter);
        assertEq(calculatedProtocolInterestRatePerSecond, protocolInterestRatePerSecondAfter);
        assertEq(loanAuctionAfter.amountDrawn, amountDrawnBefore + amountExtraOnRefinance);
    }
}
