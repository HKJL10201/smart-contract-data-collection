// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";

contract TestPartialRepayLoan is Test, OffersLoansRefinancesFixtures {
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

    function test_fuzz_partialRepayLoan_simplest_case(
        FuzzedOfferFields memory fuzzedOffer,
        uint16 secondsBeforeRepayment,
        uint8 repaymentPercentageFuzzed
    ) public validateFuzzedOfferFields(fuzzedOffer) {
        uint8 repaymentPercentage = repaymentPercentageFuzzed % 100;

        // repaymentPercentage >= 1
        repaymentPercentage = repaymentPercentage == 0 ? 1 : repaymentPercentage;

        Offer memory offerToCreate = offerStructFromFields(fuzzedOffer, defaultFixedOfferFields);

        (Offer memory offer, ) = createOfferAndTryToExecuteLoanByBorrower(
            offerToCreate,
            "should work"
        );

        uint256 repaymentAmount = (offer.amount * repaymentPercentage) / 100;

        assertionsForExecutedLoan(offer);

        vm.warp(block.timestamp + secondsBeforeRepayment);

        if (offer.asset == address(daiToken)) {
            uint256 liquidityBalanceBeforeRepay = cDAIToken.balanceOf(address(liquidity));

            LoanAuction memory loanAuction = lending.getLoanAuction(
                offer.nftContractAddress,
                offer.nftId
            );

            vm.expectEmit(true, true, false, false);
            emit PartialRepayment(
                offer.nftContractAddress,
                offer.nftId,
                repaymentAmount,
                loanAuction
            );

            vm.startPrank(borrower1);
            daiToken.approve(address(liquidity), repaymentAmount);
            lending.partialRepayLoan(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId,
                repaymentAmount
            );
            vm.stopPrank();

            // lenderRefi is false
            assertFalse(lending.getLoanAuction(address(mockNft), 1).lenderRefi);

            // Liquidity contract cToken balance
            isApproxEqual(
                cDAIToken.balanceOf(address(liquidity)),
                liquidityBalanceBeforeRepay +
                    liquidity.assetAmountToCAssetAmount(address(daiToken), repaymentAmount),
                1
            );

            // Borrower has repaymentAmount deducted
            isApproxEqual(
                daiToken.balanceOf(address(borrower1)),
                offer.amount - repaymentAmount,
                1
            );

            // Lender has repaymentAmount added
            assertCloseEnough(
                defaultDaiLiquiditySupplied - offer.amount + repaymentAmount,
                assetBalance(lender1, address(daiToken)),
                assetBalancePlusOneCToken(lender1, address(daiToken))
            );
        } else {
            uint256 liquidityBalanceBeforeRepay = cEtherToken.balanceOf(address(liquidity));

            LoanAuction memory loanAuction = lending.getLoanAuction(
                offer.nftContractAddress,
                offer.nftId
            );

            vm.expectEmit(true, true, false, false);
            emit PartialRepayment(
                offer.nftContractAddress,
                offer.nftId,
                repaymentAmount,
                loanAuction
            );

            vm.startPrank(borrower1);
            lending.partialRepayLoan{ value: repaymentAmount }(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId,
                repaymentAmount
            );
            vm.stopPrank();

            // lenderRefi is false
            assertFalse(lending.getLoanAuction(address(mockNft), 1).lenderRefi);

            // Liquidity contract cToken balance
            isApproxEqual(
                cEtherToken.balanceOf(address(liquidity)),
                liquidityBalanceBeforeRepay +
                    liquidity.assetAmountToCAssetAmount(address(ETH_ADDRESS), repaymentAmount),
                1
            );

            // Borrower has repaymentAmount deducted
            isApproxEqual(
                address(borrower1).balance,
                defaultInitialEthBalance + offer.amount - repaymentAmount,
                1
            );

            // Lender has repaymentAmount added
            assertCloseEnough(
                defaultEthLiquiditySupplied - offer.amount + repaymentAmount,
                assetBalance(lender1, address(ETH_ADDRESS)),
                assetBalancePlusOneCToken(lender1, address(ETH_ADDRESS))
            );
        }
    }

    function test_unit_partialRepayLoan_does_not_reset_gas_griefing() public {
        uint16 secondsBeforeRepayment = 12 hours;

        Offer memory offerToCreate = offerStructFromFields(
            defaultFixedFuzzedFieldsForFastUnitTesting,
            defaultFixedOfferFields
        );

        (Offer memory offer, ) = createOfferAndTryToExecuteLoanByBorrower(
            offerToCreate,
            "should work"
        );

        assertionsForExecutedLoan(offer);

        vm.warp(block.timestamp + secondsBeforeRepayment);

        uint256 interest = offer.interestRatePerSecond * secondsBeforeRepayment;

        uint256 interestShortfallBeforePartialPayment = lending.checkSufficientInterestAccumulated(
            offer.nftContractAddress,
            offer.nftId
        );

        if (offer.asset == address(daiToken)) {
            mintDai(borrower1, 1);

            vm.startPrank(borrower1);
            daiToken.approve(address(liquidity), ~uint256(0));
            lending.partialRepayLoan(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId,
                1
            );
            vm.stopPrank();
        } else {
            vm.startPrank(borrower1);
            lending.partialRepayLoan{ value: offer.amount + interest }(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId,
                1
            );
            vm.stopPrank();
        }

        uint256 interestShortfallAfter = lending.checkSufficientInterestAccumulated(
            offer.nftContractAddress,
            offer.nftId
        );

        assertEq(interestShortfallBeforePartialPayment, 0);
        assertEq(interestShortfallAfter, 24999999999999999);
    }

    function test_unit_CANNOT_partialRepayLoan_noLoan() public {
        vm.expectRevert("00007");
        lending.partialRepayLoan(
            defaultFixedOfferFields.nftContractAddress,
            defaultFixedOfferFields.nftId,
            1
        );
    }

    function test_unit_CANNOT_partialRepayLoan_someoneElsesLoan() public {
        uint16 secondsBeforeRepayment = 12 hours;

        Offer memory offerToCreate = offerStructFromFields(
            defaultFixedFuzzedFieldsForFastUnitTesting,
            defaultFixedOfferFields
        );

        (Offer memory offer, ) = createOfferAndTryToExecuteLoanByBorrower(
            offerToCreate,
            "should work"
        );

        assertionsForExecutedLoan(offer);

        vm.warp(block.timestamp + secondsBeforeRepayment);

        uint256 interest = offer.interestRatePerSecond * secondsBeforeRepayment;

        if (offer.asset == address(daiToken)) {
            mintDai(borrower1, 1);

            vm.startPrank(borrower2);
            daiToken.approve(address(liquidity), ~uint256(0));
            vm.expectRevert("00028");
            lending.partialRepayLoan(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId,
                1
            );
            vm.stopPrank();
        } else {
            vm.startPrank(borrower2);
            vm.expectRevert("00028");
            lending.partialRepayLoan{ value: offer.amount + interest }(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId,
                1
            );
            vm.stopPrank();
        }
    }

    function test_unit_partialRepayLoan_interestMath_works() public {
        uint16 secondsBeforeRepayment = 12 hours;
        uint256 amountExtraOnRefinance = 864000000;

        vm.startPrank(owner);
        lending.updateProtocolInterestBps(100);
        vm.stopPrank();

        Offer memory offerToCreate = offerStructFromFields(
            defaultFixedFuzzedFieldsForFastUnitTesting,
            defaultFixedOfferFields
        );

        (Offer memory offer, ) = createOfferAndTryToExecuteLoanByBorrower(
            offerToCreate,
            "should work"
        );

        assertionsForExecutedLoan(offer);

        vm.warp(block.timestamp + secondsBeforeRepayment);

        uint256 interest = offer.interestRatePerSecond * secondsBeforeRepayment;

        LoanAuction memory loanAuctionBefore = lending.getLoanAuction(
            defaultFixedOfferFields.nftContractAddress,
            defaultFixedOfferFields.nftId
        );

        uint256 amountDrawnBefore = loanAuctionBefore.amountDrawn;
        uint256 interestRatePerSecondBefore = loanAuctionBefore.interestRatePerSecond;

        if (offer.asset == address(daiToken)) {
            mintDai(borrower1, 1);

            vm.startPrank(borrower1);
            daiToken.approve(address(liquidity), ~uint256(0));
            lending.partialRepayLoan(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId,
                amountExtraOnRefinance
            );
            vm.stopPrank();
        } else {
            vm.startPrank(borrower1);
            lending.partialRepayLoan{ value: offer.amount + interest }(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId,
                amountExtraOnRefinance
            );
            vm.stopPrank();
        }

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

        assertEq(calculatedInterestRatePerSecond, interestRatePerSecondAfter);
        assertEq(calculatedProtocolInterestRatePerSecond, protocolInterestRatePerSecondAfter);
        assertEq(loanAuctionAfter.amountDrawn, amountDrawnBefore - amountExtraOnRefinance);
    }

    function test_fuzz_partialRepayLoan_interestMath_works(
        FuzzedOfferFields memory fuzzedOffer,
        uint16 secondsBeforeRepayment,
        uint64 amountToRepay
    ) public validateFuzzedOfferFields(fuzzedOffer) {
        vm.startPrank(owner);
        lending.updateProtocolInterestBps(100);
        vm.stopPrank();

        Offer memory offerToCreate = offerStructFromFields(fuzzedOffer, defaultFixedOfferFields);

        console.log("here");
        (Offer memory offer, ) = createOfferAndTryToExecuteLoanByBorrower(
            offerToCreate,
            "should work"
        );
        console.log("here 1");

        assertionsForExecutedLoan(offer);

        vm.warp(block.timestamp + secondsBeforeRepayment + 1);

        uint256 interest = offer.interestRatePerSecond * secondsBeforeRepayment;

        LoanAuction memory loanAuctionBefore = lending.getLoanAuction(
            defaultFixedOfferFields.nftContractAddress,
            defaultFixedOfferFields.nftId
        );

        vm.assume(amountToRepay > 0);
        vm.assume(amountToRepay < loanAuctionBefore.amountDrawn);

        uint256 amountDrawnBefore = loanAuctionBefore.amountDrawn;
        uint256 interestRatePerSecondBefore = loanAuctionBefore.interestRatePerSecond;

        if (offer.asset == address(daiToken)) {
            mintDai(borrower1, 1);

            vm.startPrank(borrower1);
            daiToken.approve(address(liquidity), ~uint256(0));
            lending.partialRepayLoan(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId,
                amountToRepay
            );
            vm.stopPrank();
        } else {
            vm.startPrank(borrower1);
            lending.partialRepayLoan{ value: offer.amount + interest }(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId,
                amountToRepay
            );
            vm.stopPrank();
        }

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

        assertEq(calculatedInterestRatePerSecond, interestRatePerSecondAfter);
        assertEq(calculatedProtocolInterestRatePerSecond, protocolInterestRatePerSecondAfter);
        assertEq(loanAuctionAfter.amountDrawn, amountDrawnBefore - amountToRepay);
    }

    function test_unit_CANNOT_partialRepayLoan_loanExpired() public {
        uint8 repaymentPercentageFuzzed = 50;
        uint8 repaymentPercentage = repaymentPercentageFuzzed % 100;

        // repaymentPercentage >= 1
        repaymentPercentage = repaymentPercentage == 0 ? 1 : repaymentPercentage;

        Offer memory offerToCreate = offerStructFromFields(
            defaultFixedFuzzedFieldsForFastUnitTesting,
            defaultFixedOfferFields
        );

        (Offer memory offer, ) = createOfferAndTryToExecuteLoanByBorrower(
            offerToCreate,
            "should work"
        );

        uint256 repaymentAmount = (offer.amount * repaymentPercentage) / 100;

        assertionsForExecutedLoan(offer);

        vm.warp(
            block.timestamp +
                lending.getLoanAuction(offer.nftContractAddress, offer.nftId).loanEndTimestamp +
                1
        );

        if (offer.asset == address(daiToken)) {
            vm.startPrank(borrower1);
            daiToken.approve(address(liquidity), repaymentAmount);
            vm.expectRevert("00009");

            lending.partialRepayLoan(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId,
                repaymentAmount
            );
            vm.stopPrank();
        } else {
            vm.startPrank(borrower1);
            vm.expectRevert("00009");

            lending.partialRepayLoan{ value: repaymentAmount }(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId,
                repaymentAmount
            );
            vm.stopPrank();
        }
    }
}
