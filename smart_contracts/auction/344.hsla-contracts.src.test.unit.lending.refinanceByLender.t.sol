// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";

contract TestRefinanceByLender is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function refinanceSetup(FuzzedOfferFields memory fuzzed, uint16 secondsBeforeRefinance)
        private
    {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");

        assertionsForExecutedLoan(offer);

        uint256 amountDrawn = lending
            .getLoanAuction(offer.nftContractAddress, offer.nftId)
            .amountDrawn;

        vm.warp(block.timestamp + secondsBeforeRefinance);

        uint256 interestShortfall = lending.checkSufficientInterestAccumulated(
            offer.nftContractAddress,
            offer.nftId
        );

        defaultFixedOfferFields.creator = lender2;
        fuzzed.duration = fuzzed.duration + 1; // make sure offer is better
        fuzzed.floorTerm = false; // refinance can't be floor term
        fuzzed.expiration = uint32(block.timestamp) + secondsBeforeRefinance + 1;
        fuzzed.amount = uint128(
            offer.amount +
                (offer.interestRatePerSecond * secondsBeforeRefinance) +
                interestShortfall +
                ((amountDrawn * lending.protocolInterestBps()) / 10_000)
        );

        Offer memory newOffer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        uint256 beforeRefinanceLenderBalance = assetBalance(lender1, address(daiToken));

        if (offer.asset == address(daiToken)) {
            beforeRefinanceLenderBalance = assetBalance(lender1, address(daiToken));
        } else {
            beforeRefinanceLenderBalance = assetBalance(lender1, ETH_ADDRESS);
        }

        (uint256 lenderInterest, uint256 protocolInterest) = lending.calculateInterestAccrued(
            newOffer.nftContractAddress,
            newOffer.nftId
        );

        LoanAuction memory loanAuction = tryToRefinanceByLender(newOffer, "should work");

        assertionsForExecutedLenderRefinance(
            offer,
            newOffer,
            loanAuction,
            secondsBeforeRefinance,
            interestShortfall,
            beforeRefinanceLenderBalance
        );
        assertEq(loanAuction.accumulatedLenderInterest, lenderInterest);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, protocolInterest);
        assertEq(loanAuction.slashableLenderInterest, 0);
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

    function assertionsForExecutedLenderRefinance(
        Offer memory offer1,
        Offer memory offer2,
        LoanAuction memory loanAuction,
        uint16 secondsBeforeRefinance,
        uint256 interestShortfall,
        uint256 beforeRefinanceLenderBalance
    ) private {
        // lender1 has money
        if (offer2.asset == address(daiToken)) {
            assertCloseEnough(
                beforeRefinanceLenderBalance +
                    loanAuction.amountDrawn +
                    (offer1.interestRatePerSecond * secondsBeforeRefinance) +
                    interestShortfall +
                    ((loanAuction.amountDrawn * lending.originationPremiumBps()) / 10_000),
                assetBalance(lender1, address(daiToken)),
                assetBalancePlusOneCToken(lender1, address(daiToken))
            );
        } else {
            assertCloseEnough(
                beforeRefinanceLenderBalance +
                    loanAuction.amountDrawn +
                    (offer1.interestRatePerSecond * secondsBeforeRefinance) +
                    interestShortfall +
                    ((loanAuction.amountDrawn * lending.originationPremiumBps()) / 10_000),
                assetBalance(lender1, ETH_ADDRESS),
                assetBalancePlusOneCToken(lender1, ETH_ADDRESS)
            );
        }

        // lender2 is now lender
        assertEq(loanAuction.lender, offer2.creator);
        assertEq(loanAuction.loanBeginTimestamp, loanAuction.loanEndTimestamp - offer2.duration);
        assertEq(loanAuction.nftOwner, borrower1);
        assertEq(loanAuction.loanEndTimestamp, loanAuction.loanBeginTimestamp + offer2.duration);
        assertTrue(!loanAuction.fixedTerms);
        assertEq(loanAuction.interestRatePerSecond, offer2.interestRatePerSecond);
        assertEq(loanAuction.asset, offer2.asset);
        assertEq(loanAuction.lenderRefi, true);
        assertEq(loanAuction.amount, offer2.amount);
        assertEq(loanAuction.amountDrawn, offer1.amount);

        uint256 calcProtocolInterestPerSecond = lending.calculateInterestPerSecond(
            loanAuction.amountDrawn,
            lending.protocolInterestBps(),
            offer1.duration
        );

        assertEq(loanAuction.protocolInterestRatePerSecond, calcProtocolInterestPerSecond);
    }

    function _test_refinanceByLender_simplest_case(
        FuzzedOfferFields memory fuzzed,
        uint16 secondsBeforeRefinance
    ) private {
        refinanceSetup(fuzzed, secondsBeforeRefinance);
    }

    function test_fuzz_refinanceByLender_simplest_case(
        FuzzedOfferFields memory fuzzed,
        uint16 secondsBeforeRefinance,
        uint16 gasGriefingPremiumBps,
        uint16 protocolInterestBps
    ) public validateFuzzedOfferFields(fuzzed) {
        vm.assume(gasGriefingPremiumBps <= MAX_FEE);
        vm.assume(protocolInterestBps <= MAX_FEE);
        vm.startPrank(owner);
        lending.updateProtocolInterestBps(protocolInterestBps);
        lending.updateGasGriefingPremiumBps(gasGriefingPremiumBps);
        vm.stopPrank();
        _test_refinanceByLender_simplest_case(fuzzed, secondsBeforeRefinance);
    }

    function test_unit_refinanceByLender_simplest_case_dai() public {
        FuzzedOfferFields memory fixedForSpeed1 = defaultFixedFuzzedFieldsForFastUnitTesting;
        FuzzedOfferFields memory fixedForSpeed2 = defaultFixedFuzzedFieldsForFastUnitTesting;

        fixedForSpeed2.duration += 1 days;
        uint16 secondsBeforeRefinance = 12 hours;

        fixedForSpeed1.randomAsset = 0; // DAI
        fixedForSpeed2.randomAsset = 0; // DAI
        _test_refinanceByLender_simplest_case(fixedForSpeed1, secondsBeforeRefinance);
    }

    function test_unit_CANNOT_refinanceByLender_lenderNotOfferCreator() public {
        FuzzedOfferFields memory fixedForSpeed1 = defaultFixedFuzzedFieldsForFastUnitTesting;
        FuzzedOfferFields memory fixedForSpeed2 = defaultFixedFuzzedFieldsForFastUnitTesting;

        fixedForSpeed2.duration += 1 days;
        uint16 secondsBeforeRefinance = 12 hours;

        Offer memory offer = offerStructFromFields(fixedForSpeed1, defaultFixedOfferFields);

        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");

        assertionsForExecutedLoan(offer);

        uint256 amountDrawn = lending
            .getLoanAuction(offer.nftContractAddress, offer.nftId)
            .amountDrawn;

        vm.warp(block.timestamp + secondsBeforeRefinance);

        uint256 interestShortfall = lending.checkSufficientInterestAccumulated(
            offer.nftContractAddress,
            offer.nftId
        );

        defaultFixedOfferFields.creator = borrower2;
        fixedForSpeed2.duration = fixedForSpeed2.duration + 1; // make sure offer is better
        fixedForSpeed2.floorTerm = false; // refinance can't be floor term
        fixedForSpeed2.expiration = uint32(block.timestamp) + secondsBeforeRefinance + 1;
        fixedForSpeed2.amount = uint128(
            offer.amount +
                (offer.interestRatePerSecond * secondsBeforeRefinance) +
                interestShortfall +
                ((amountDrawn * lending.protocolInterestBps()) / 10_000)
        );

        LoanAuction memory loanAuction = lending.getLoanAuction(address(mockNft), 1);

        Offer memory newOffer = offerStructFromFields(fixedForSpeed2, defaultFixedOfferFields);

        vm.startPrank(lender2);
        vm.expectRevert("00024");
        lending.refinanceByLender(newOffer, loanAuction.lastUpdatedTimestamp);
        vm.stopPrank();
    }

    function test_unit_CANNOT_refinanceByLender_loanAlreadyExpired() public {
        FuzzedOfferFields memory fixedForSpeed1 = defaultFixedFuzzedFieldsForFastUnitTesting;
        FuzzedOfferFields memory fixedForSpeed2 = defaultFixedFuzzedFieldsForFastUnitTesting;

        fixedForSpeed2.duration += 1 days;
        uint16 secondsBeforeRefinance = 12 hours;

        Offer memory offer = offerStructFromFields(fixedForSpeed1, defaultFixedOfferFields);

        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");

        assertionsForExecutedLoan(offer);

        uint256 amountDrawn = lending
            .getLoanAuction(offer.nftContractAddress, offer.nftId)
            .amountDrawn;

        vm.warp(block.timestamp + secondsBeforeRefinance);

        uint256 interestShortfall = lending.checkSufficientInterestAccumulated(
            offer.nftContractAddress,
            offer.nftId
        );

        defaultFixedOfferFields.creator = lender2;
        fixedForSpeed2.duration = fixedForSpeed2.duration + 1; // make sure offer is better
        fixedForSpeed2.floorTerm = false; // refinance can't be floor term
        fixedForSpeed2.expiration = uint32(block.timestamp) + secondsBeforeRefinance + 1;
        fixedForSpeed2.amount = uint128(
            offer.amount +
                (offer.interestRatePerSecond * secondsBeforeRefinance) +
                interestShortfall +
                ((amountDrawn * lending.protocolInterestBps()) / 10_000)
        );

        LoanAuction memory loanAuction = lending.getLoanAuction(address(mockNft), 1);

        Offer memory newOffer = offerStructFromFields(fixedForSpeed2, defaultFixedOfferFields);

        vm.warp(loanAuction.loanEndTimestamp + 1);
        vm.startPrank(lender2);
        vm.expectRevert("00009");
        lending.refinanceByLender(newOffer, loanAuction.lastUpdatedTimestamp);
        vm.stopPrank();
    }

    function test_unit_refinanceByLender_simplest_slashed() public {
        resetSuppliedDaiLiquidity(lender2, 2000 * 10**daiToken.decimals());

        // Borrower1/Lender1 originate loan
        FuzzedOfferFields memory fuzzed = defaultFixedFuzzedFieldsForFastUnitTesting;
        fuzzed.randomAsset = 0; // DAI
        fuzzed.amount = uint128(1000 * 10**daiToken.decimals()); // $1000

        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");

        assertionsForExecutedLoan(offer);

        // 1 hour passes after loan execution
        vm.warp(block.timestamp + 1 hours);

        LoanAuction memory loanAuctionBeforeRefinance = lending.getLoanAuction(
            offer.nftContractAddress,
            offer.nftId
        );

        // accumulated is 0
        assertEq(loanAuctionBeforeRefinance.accumulatedLenderInterest, 0);
        // slashable is 0
        assertEq(loanAuctionBeforeRefinance.slashableLenderInterest, 0);
        // should have 1 hour of accrued interest
        (uint256 lenderAccruedInterest, uint256 protocolAccruedInterest) = lending
            .calculateInterestAccrued(offer.nftContractAddress, offer.nftId);
        assertEq(lenderAccruedInterest, 1 hours * loanAuctionBeforeRefinance.interestRatePerSecond);
        // lenderRefi should be false
        assertEq(loanAuctionBeforeRefinance.lenderRefi, false);

        // set up refinance
        defaultFixedOfferFields.creator = lender2;
        fuzzed.expiration = uint32(block.timestamp) + 1 hours + 1;
        fuzzed.amount = uint128(1000 * 10**daiToken.decimals() + 900 * 10**daiToken.decimals());

        Offer memory newOffer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        tryToRefinanceByLender(newOffer, "should work");

        LoanAuction memory loanAuctionBeforeDraw = lending.getLoanAuction(
            offer.nftContractAddress,
            offer.nftId
        );

        // 1 hour of interest becomes accumulated
        assertEq(
            loanAuctionBeforeDraw.accumulatedLenderInterest,
            1 hours * loanAuctionBeforeDraw.interestRatePerSecond
        );
        // slashable is 0
        assertEq(loanAuctionBeforeDraw.slashableLenderInterest, 0);
        // 0 accrued (this became accumulated)
        (lenderAccruedInterest, protocolAccruedInterest) = lending.calculateInterestAccrued(
            offer.nftContractAddress,
            offer.nftId
        );
        assertEq(lenderAccruedInterest, 0);
        // lenderRefi switches to true
        assertEq(loanAuctionBeforeDraw.lenderRefi, true);

        // 1 hour passes after refinance
        vm.warp(block.timestamp + 1 hours);

        // 1 hour of interest still accumulated
        assertEq(
            loanAuctionBeforeDraw.accumulatedLenderInterest,
            1 hours * loanAuctionBeforeDraw.interestRatePerSecond
        );
        // slashable is 0
        assertEq(loanAuctionBeforeDraw.slashableLenderInterest, 0);
        // but 1 new hour of interest accrued
        (lenderAccruedInterest, protocolAccruedInterest) = lending.calculateInterestAccrued(
            offer.nftContractAddress,
            offer.nftId
        );
        assertEq(lenderAccruedInterest, 1 hours * loanAuctionBeforeDraw.interestRatePerSecond);
        // lenderRefi still true
        assertEq(loanAuctionBeforeDraw.lenderRefi, true);

        // ensure attempt to draw 1000 DAI overdraws
        vm.startPrank(lender2);
        liquidity.withdrawErc20(address(daiToken), 500 * 10**daiToken.decimals());
        vm.stopPrank();

        // borrower attempts to draw 1000 DAI
        vm.startPrank(borrower1);
        lending.drawLoanAmount(
            offer.nftContractAddress,
            offer.nftId,
            900 * 10**daiToken.decimals()
        );
        vm.stopPrank();

        LoanAuction memory loanAuctionAfterDraw = lending.getLoanAuction(
            offer.nftContractAddress,
            offer.nftId
        );

        // 1 hour of interest still accumulated
        assertEq(
            loanAuctionAfterDraw.accumulatedLenderInterest,
            1 hours * loanAuctionBeforeDraw.interestRatePerSecond
        );
        // slashable is 0
        assertEq(loanAuctionAfterDraw.slashableLenderInterest, 0);
        (lenderAccruedInterest, protocolAccruedInterest) = lending.calculateInterestAccrued(
            offer.nftContractAddress,
            offer.nftId
        );
        // 1 hour of interest accrued has been slashed
        // (in drawLoanAmount, this gets turned into slashable in _updateInterest,
        // and slashable gets set to 0 in _slashUnsupportedAmount)
        assertEq(lenderAccruedInterest, 0);
        // lenderRefi toggled back to false
        assertEq(loanAuctionAfterDraw.lenderRefi, false);

        // 1 hour passes after draw and slash
        vm.warp(block.timestamp + 1 hours);

        // 1 hour of interest still accumulated
        assertEq(
            loanAuctionAfterDraw.accumulatedLenderInterest,
            1 hours * loanAuctionBeforeDraw.interestRatePerSecond
        );
        // slashable 0
        assertEq(loanAuctionAfterDraw.slashableLenderInterest, 0);
        // lenderRefi still false
        assertEq(loanAuctionAfterDraw.lenderRefi, false);
        // but 1 new hour of accrued interest
        (lenderAccruedInterest, protocolAccruedInterest) = lending.calculateInterestAccrued(
            offer.nftContractAddress,
            offer.nftId
        );
        assertEq(lenderAccruedInterest, 1 hours * loanAuctionAfterDraw.interestRatePerSecond);

        uint256 interestThreshold = (uint256(loanAuctionAfterDraw.amountDrawn) *
            lending.gasGriefingPremiumBps()) / MAX_BPS;

        uint256 interestDelta = interestThreshold - lenderAccruedInterest;

        uint256 protocolInterest = loanAuctionAfterDraw.accumulatedPaidProtocolInterest +
            loanAuctionAfterDraw.unpaidProtocolInterest +
            protocolAccruedInterest;

        // set up borrower repay full amount
        mintDai(borrower1, 10_000 * 10**daiToken.decimals() + interestDelta);
        vm.startPrank(borrower1);
        daiToken.approve(address(liquidity), 10_000 * 10**daiToken.decimals());

        // most important part here is the amount repaid, the last argument to the event
        // the amount drawn + 1 hour at initial interest rate + 1 hour at "after draw" interest rate
        // even though the borrower couldn't draw 1000 DAI, they could draw some, so the rate changes

        vm.expectEmit(true, true, false, false);
        emit LoanRepaid(
            offer.nftContractAddress,
            offer.nftId,
            loanAuctionAfterDraw.amountDrawn +
                1 hours *
                loanAuctionBeforeDraw.interestRatePerSecond +
                1 hours *
                loanAuctionAfterDraw.interestRatePerSecond +
                protocolInterest,
            loanAuctionAfterDraw
        );

        lending.repayLoan(offer.nftContractAddress, offer.nftId);
        vm.stopPrank();

        // check borrower balance
        assertEq(assetBalance(borrower1, address(daiToken)), 0);

        // check lender balance
        assertCloseEnough(
            loanAuctionAfterDraw.amountDrawn +
                1 hours *
                loanAuctionBeforeDraw.interestRatePerSecond +
                1 hours *
                loanAuctionAfterDraw.interestRatePerSecond +
                interestDelta,
            assetBalance(lender2, address(daiToken)),
            assetBalancePlusOneCToken(lender2, address(daiToken))
        );
    }

    function test_unit_refinanceByLender_same_lender_refinances_twice_slashed() public {
        resetSuppliedDaiLiquidity(lender2, 2000 * 10**daiToken.decimals());

        // Borrower1/Lender1 originate loan
        FuzzedOfferFields memory fuzzed = defaultFixedFuzzedFieldsForFastUnitTesting;
        fuzzed.randomAsset = 0; // DAI
        fuzzed.amount = uint128(1000 * 10**daiToken.decimals()); // $1000

        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");

        assertionsForExecutedLoan(offer);

        // 1 hour passes after loan execution
        vm.warp(block.timestamp + 1 hours);

        LoanAuction memory loanAuctionBeforeRefinance = lending.getLoanAuction(
            offer.nftContractAddress,
            offer.nftId
        );

        // accumulated is 0
        assertEq(loanAuctionBeforeRefinance.accumulatedLenderInterest, 0);
        // slashable is 0
        assertEq(loanAuctionBeforeRefinance.slashableLenderInterest, 0);
        // should have 1 hour of accrued interest
        (uint256 lenderAccruedInterest, uint256 protocolAccruedInterest) = lending
            .calculateInterestAccrued(offer.nftContractAddress, offer.nftId);
        assertEq(lenderAccruedInterest, 1 hours * loanAuctionBeforeRefinance.interestRatePerSecond);
        // lenderRefi should be false
        assertEq(loanAuctionBeforeRefinance.lenderRefi, false);

        // set up refinance
        defaultFixedOfferFields.creator = lender2;
        fuzzed.expiration = uint32(block.timestamp) + 1 hours + 1;
        fuzzed.amount = uint128(1000 * 10**daiToken.decimals() + 500 * 10**daiToken.decimals());

        Offer memory newOffer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        tryToRefinanceByLender(newOffer, "should work");

        LoanAuction memory loanAuctionBeforeDraw = lending.getLoanAuction(
            offer.nftContractAddress,
            offer.nftId
        );

        // 1 hour of interest becomes accumulated
        assertEq(
            loanAuctionBeforeDraw.accumulatedLenderInterest,
            1 hours * loanAuctionBeforeDraw.interestRatePerSecond
        );
        // slashable is 0
        assertEq(loanAuctionBeforeDraw.slashableLenderInterest, 0);
        // 0 accrued (this became accumulated)
        (lenderAccruedInterest, protocolAccruedInterest) = lending.calculateInterestAccrued(
            offer.nftContractAddress,
            offer.nftId
        );
        assertEq(lenderAccruedInterest, 0);
        // lenderRefi switches to true
        assertEq(loanAuctionBeforeDraw.lenderRefi, true);

        // 1 hour passes after refinance
        vm.warp(block.timestamp + 1 hours);

        // set up 2nd refinance
        defaultFixedOfferFields.creator = lender2;
        fuzzed.expiration = uint32(block.timestamp) + 1 hours + 1;
        fuzzed.amount = uint128(1000 * 10**daiToken.decimals() + 900 * 10**daiToken.decimals());

        Offer memory newOffer2 = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        tryToRefinanceByLender(newOffer2, "should work");

        loanAuctionBeforeDraw = lending.getLoanAuction(offer.nftContractAddress, offer.nftId);

        // 2 hour of interest becomes accumulated
        assertEq(
            loanAuctionBeforeDraw.accumulatedLenderInterest,
            1 hours * loanAuctionBeforeDraw.interestRatePerSecond
        );
        // slashable is 1
        assertEq(
            loanAuctionBeforeDraw.slashableLenderInterest,
            1 hours * loanAuctionBeforeDraw.interestRatePerSecond
        );
        // 0 accrued (this became accumulated)
        (lenderAccruedInterest, protocolAccruedInterest) = lending.calculateInterestAccrued(
            offer.nftContractAddress,
            offer.nftId
        );
        assertEq(lenderAccruedInterest, 0);
        // lenderRefi switches to true
        assertEq(loanAuctionBeforeDraw.lenderRefi, true);

        // 1 hour passes after refinance
        vm.warp(block.timestamp + 1 hours);

        // 1 hour of interest still accumulated
        assertEq(
            loanAuctionBeforeDraw.accumulatedLenderInterest,
            1 hours * loanAuctionBeforeDraw.interestRatePerSecond
        );
        // slashable is 0
        assertEq(
            loanAuctionBeforeDraw.slashableLenderInterest,
            1 hours * loanAuctionBeforeDraw.interestRatePerSecond
        );
        // but 1 new hour of interest accrued
        (lenderAccruedInterest, protocolAccruedInterest) = lending.calculateInterestAccrued(
            offer.nftContractAddress,
            offer.nftId
        );
        assertEq(lenderAccruedInterest, 1 hours * loanAuctionBeforeDraw.interestRatePerSecond);
        // lenderRefi still true
        assertEq(loanAuctionBeforeDraw.lenderRefi, true);

        // ensure attempt to draw 1000 DAI overdraws
        vm.startPrank(lender2);
        liquidity.withdrawErc20(address(daiToken), 500 * 10**daiToken.decimals());
        vm.stopPrank();

        // borrower attempts to draw 1000 DAI
        vm.startPrank(borrower1);
        lending.drawLoanAmount(
            offer.nftContractAddress,
            offer.nftId,
            600 * 10**daiToken.decimals()
        );
        vm.stopPrank();

        LoanAuction memory loanAuctionAfterDraw = lending.getLoanAuction(
            offer.nftContractAddress,
            offer.nftId
        );

        // 1 hour of interest still accumulated
        assertEq(
            loanAuctionAfterDraw.accumulatedLenderInterest,
            1 hours * loanAuctionBeforeDraw.interestRatePerSecond
        );
        // slashable is 0
        assertEq(loanAuctionAfterDraw.slashableLenderInterest, 0);
        (lenderAccruedInterest, protocolAccruedInterest) = lending.calculateInterestAccrued(
            offer.nftContractAddress,
            offer.nftId
        );
        // 1 hour of interest accrued has been slashed
        // (in drawLoanAmount, this gets turned into slashable in _updateInterest,
        // and slashable gets set to 0 in _slashUnsupportedAmount)
        assertEq(lenderAccruedInterest, 0);
        // lenderRefi toggled back to false
        assertEq(loanAuctionAfterDraw.lenderRefi, false);

        // 1 hour passes after draw and slash
        vm.warp(block.timestamp + 1 hours);

        // 1 hour of interest still accumulated
        assertEq(
            loanAuctionAfterDraw.accumulatedLenderInterest,
            1 hours * loanAuctionBeforeDraw.interestRatePerSecond
        );
        // slashable 0
        assertEq(loanAuctionAfterDraw.slashableLenderInterest, 0);
        // lenderRefi still false
        assertEq(loanAuctionAfterDraw.lenderRefi, false);
        // but 1 new hour of accrued interest
        (lenderAccruedInterest, protocolAccruedInterest) = lending.calculateInterestAccrued(
            offer.nftContractAddress,
            offer.nftId
        );
        assertEq(lenderAccruedInterest, 1 hours * loanAuctionAfterDraw.interestRatePerSecond);

        uint256 interestThreshold = (uint256(loanAuctionAfterDraw.amountDrawn) *
            lending.gasGriefingPremiumBps()) / MAX_BPS;

        uint256 interestDelta = interestThreshold - lenderAccruedInterest;

        uint256 protocolInterest = loanAuctionAfterDraw.accumulatedPaidProtocolInterest +
            loanAuctionAfterDraw.unpaidProtocolInterest +
            protocolAccruedInterest;

        // set up borrower repay full amount
        mintDai(
            borrower1,
            loanAuctionAfterDraw.amountDrawn +
                1 hours *
                loanAuctionBeforeDraw.interestRatePerSecond +
                1 hours *
                loanAuctionAfterDraw.interestRatePerSecond +
                protocolInterest +
                interestDelta
        );

        vm.startPrank(borrower1);
        daiToken.approve(address(liquidity), ~uint256(0));

        // most important part here is the amount repaid, the last argument to the event
        // the amount drawn + 1 hour at initial interest rate + 1 hour at "after draw" interest rate
        // even though the borrower couldn't draw 1000 DAI, they could draw some, so the rate changes
        vm.expectEmit(true, true, false, false);
        emit LoanRepaid(
            offer.nftContractAddress,
            offer.nftId,
            loanAuctionAfterDraw.amountDrawn +
                1 hours *
                loanAuctionBeforeDraw.interestRatePerSecond +
                1 hours *
                loanAuctionAfterDraw.interestRatePerSecond +
                protocolInterest,
            loanAuctionAfterDraw
        );

        lending.repayLoan(offer.nftContractAddress, offer.nftId);
        vm.stopPrank();

        // check borrower balance
        assertEq(assetBalance(borrower1, address(daiToken)), 0);

        // check lender balance
        assertCloseEnough(
            loanAuctionAfterDraw.amountDrawn +
                1 hours *
                loanAuctionBeforeDraw.interestRatePerSecond +
                1 hours *
                loanAuctionAfterDraw.interestRatePerSecond +
                interestDelta,
            assetBalance(lender2, address(daiToken)),
            assetBalancePlusOneCToken(lender2, address(daiToken))
        );
    }

    function test_unit_refinanceByLender_simplest_case_eth() public {
        FuzzedOfferFields memory fixedForSpeed = defaultFixedFuzzedFieldsForFastUnitTesting;
        fixedForSpeed.randomAsset = 1; // ETH
        uint16 secondsBeforeRefinance = 12 hours;

        _test_refinanceByLender_simplest_case(fixedForSpeed, secondsBeforeRefinance);
    }

    function _test_refinanceByLender_events(FuzzedOfferFields memory fuzzed) private {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        LoanAuction memory loanAuction = lending.getLoanAuction(
            offer.nftContractAddress,
            offer.nftId
        );

        vm.expectEmit(true, true, false, false);
        emit LoanExecuted(offer.nftContractAddress, offer.nftId, loanAuction);

        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");
    }

    function test_unit_refinanceByLender_events() public {
        _test_refinanceByLender_events(defaultFixedFuzzedFieldsForFastUnitTesting);
    }

    function test_fuzz_refinanceByLender_events(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_refinanceByLender_events(fuzzed);
    }

    function _test_cannot_refinanceByLender_if_offer_expired(FuzzedOfferFields memory fuzzed)
        private
    {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        createOffer(offer, lender1);
        vm.warp(offer.expiration);
        approveLending(offer);
        tryToExecuteLoanByBorrower(offer, "00010");
    }

    function test_fuzz_cannot_refinanceByLender_if_offer_expired(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_cannot_refinanceByLender_if_offer_expired(fuzzed);
    }

    function test_unit_cannot_refinanceByLender_if_offer_expired() public {
        _test_cannot_refinanceByLender_if_offer_expired(defaultFixedFuzzedFieldsForFastUnitTesting);
    }

    function _test_cannot_refinanceByLender_if_asset_not_in_allow_list(
        FuzzedOfferFields memory fuzzed
    ) public {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        createOffer(offer, lender1);
        vm.startPrank(owner);
        liquidity.setCAssetAddress(offer.asset, address(0));
        vm.stopPrank();
        tryToExecuteLoanByBorrower(offer, "00040");
    }

    function test_fuzz_cannot_refinanceByLender_if_asset_not_in_allow_list(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_cannot_refinanceByLender_if_asset_not_in_allow_list(fuzzed);
    }

    function test_unit_cannot_refinanceByLender_if_asset_not_in_allow_list() public {
        _test_cannot_refinanceByLender_if_asset_not_in_allow_list(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_refinanceByLender_if_offer_not_created(FuzzedOfferFields memory fuzzed)
        private
    {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        // notice conspicuous absence of createOffer here
        approveLending(offer);
        tryToExecuteLoanByBorrower(offer, "00022");
    }

    function test_fuzz_cannot_refinanceByLender_if_offer_not_created(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_cannot_refinanceByLender_if_offer_not_created(fuzzed);
    }

    function test_unit_cannot_refinanceByLender_if_offer_not_created() public {
        _test_cannot_refinanceByLender_if_offer_not_created(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_refinanceByLender_if_dont_own_nft(FuzzedOfferFields memory fuzzed)
        private
    {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        createOffer(offer, lender1);
        approveLending(offer);
        vm.startPrank(borrower1);
        mockNft.safeTransferFrom(borrower1, borrower2, 1);
        vm.stopPrank();
        tryToExecuteLoanByBorrower(offer, "00018");
    }

    function test_fuzz_cannot_refinanceByLender_if_dont_own_nft(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_cannot_refinanceByLender_if_dont_own_nft(fuzzed);
    }

    function test_unit_cannot_refinanceByLender_if_dont_own_nft() public {
        _test_cannot_refinanceByLender_if_dont_own_nft(defaultFixedFuzzedFieldsForFastUnitTesting);
    }

    function _test_cannot_refinanceByLender_if_not_enough_tokens(FuzzedOfferFields memory fuzzed)
        private
    {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        createOffer(offer, lender1);
        approveLending(offer);

        vm.startPrank(lender1);
        if (offer.asset == address(daiToken)) {
            liquidity.withdrawErc20(address(daiToken), defaultDaiLiquiditySupplied);
        } else {
            liquidity.withdrawEth(defaultEthLiquiditySupplied);
        }
        vm.stopPrank();

        tryToExecuteLoanByBorrower(offer, "00034");
    }

    function test_fuzz_cannot_refinanceByLender_if_not_enough_tokens(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_cannot_refinanceByLender_if_not_enough_tokens(fuzzed);
    }

    function test_unit_cannot_refinanceByLender_if_not_enough_tokens() public {
        _test_cannot_refinanceByLender_if_not_enough_tokens(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_refinanceByLender_if_underlying_transfer_fails(
        FuzzedOfferFields memory fuzzed
    ) private {
        // Can only be mocked
        bool integration = false;
        try vm.envBool("INTEGRATION") returns (bool isIntegration) {
            integration = isIntegration;
        } catch (bytes memory) {
            // This catches revert that occurs if env variable not supplied
        }

        if (!integration) {
            fuzzed.randomAsset = 0; // DAI
            Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
            daiToken.setTransferFail(true);
            createOfferAndTryToExecuteLoanByBorrower(
                offer,
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }

    function test_fuzz_cannot_refinanceByLender_if_underlying_transfer_fails(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_cannot_refinanceByLender_if_underlying_transfer_fails(fuzzed);
    }

    function test_unit_cannot_refinanceByLender_if_underlying_transfer_fails() public {
        _test_cannot_refinanceByLender_if_underlying_transfer_fails(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    // function _test_cannot_refinanceByLender_if_eth_transfer_fails(FuzzedOfferFields memory fuzzed)
    //     private
    // {
    //     fuzzed.randomAsset = 1; // ETH
    //     Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

    //     // give NFT to contract
    //     vm.startPrank(borrower1);
    //     mockNft.safeTransferFrom(borrower1, address(contractThatCannotReceiveEth), 1);
    //     vm.stopPrank();

    //     // set borrower1 to contract
    //     borrower1 = payable(address(contractThatCannotReceiveEth));

    //     createOfferAndTryToExecuteLoanByBorrower(
    //         offer,
    //         "Address: unable to send value, recipient may have reverted"
    //     );
    // }

    // function test_fuzz_cannot_refinanceByLender_if_eth_transfer_fails(
    //     FuzzedOfferFields memory fuzzed
    // ) public validateFuzzedOfferFields(fuzzed) {
    //     _test_cannot_refinanceByLender_if_eth_transfer_fails(fuzzed);
    // }

    // function test_unit_cannot_refinanceByLender_if_eth_transfer_fails() public {
    //     _test_cannot_refinanceByLender_if_eth_transfer_fails(
    //         defaultFixedFuzzedFieldsForFastUnitTesting
    //     );
    // }

    function _test_cannot_refinanceByLender_if_borrower_offer(FuzzedOfferFields memory fuzzed)
        private
    {
        defaultFixedOfferFields.lenderOffer = false;
        fuzzed.floorTerm = false; // borrower can't make a floor term offer

        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        // pass NFT to lender1 so they can make a borrower offer
        vm.startPrank(borrower1);
        mockNft.safeTransferFrom(borrower1, lender1, 1);
        vm.stopPrank();

        createOffer(offer, lender1);

        // pass NFT back to borrower1 so they can try to execute a borrower offer
        vm.startPrank(lender1);
        mockNft.safeTransferFrom(lender1, borrower1, 1);
        vm.stopPrank();

        approveLending(offer);
        tryToExecuteLoanByBorrower(offer, "00012");
    }

    function test_fuzz_refinanceByLender_if_borrower_offer(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_cannot_refinanceByLender_if_borrower_offer(fuzzed);
    }

    function test_unit_refinanceByLender_if_borrower_offer() public {
        _test_cannot_refinanceByLender_if_borrower_offer(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_refinanceByLender_if_loan_active(FuzzedOfferFields memory fuzzed)
        private
    {
        defaultFixedOfferFields.lenderOffer = true;
        fuzzed.floorTerm = true;

        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        offer.floorTermLimit = 2;

        createOffer(offer, lender1);

        approveLending(offer);
        tryToExecuteLoanByBorrower(offer, "should work");

        tryToExecuteLoanByBorrower(offer, "00006");
    }

    function test_fuzz_refinanceByLender_if_loan_active(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_cannot_refinanceByLender_if_loan_active(fuzzed);
    }

    function test_unit_refinanceByLender_if_loan_active() public {
        _test_cannot_refinanceByLender_if_loan_active(defaultFixedFuzzedFieldsForFastUnitTesting);
    }

    function test_unit_refinanceByLender_term_griefing_math() public {
        Offer memory offer = offerStructFromFields(
            defaultFixedFuzzedFieldsForFastUnitTesting,
            defaultFixedOfferFields
        );

        uint16 secondsBeforeRefinance = 100;

        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");

        assertionsForExecutedLoan(offer);

        vm.warp(block.timestamp + secondsBeforeRefinance);

        defaultFixedOfferFields.creator = lender2;
        defaultFixedFuzzedFieldsForFastUnitTesting.duration =
            defaultFixedFuzzedFieldsForFastUnitTesting.duration +
            1; // make sure offer is better
        defaultFixedFuzzedFieldsForFastUnitTesting.floorTerm = false; // refinance can't be floor term
        defaultFixedFuzzedFieldsForFastUnitTesting.expiration =
            uint32(block.timestamp) +
            secondsBeforeRefinance +
            1;
        defaultFixedFuzzedFieldsForFastUnitTesting.amount = uint128(offer.amount);

        Offer memory newOffer = offerStructFromFields(
            defaultFixedFuzzedFieldsForFastUnitTesting,
            defaultFixedOfferFields
        );

        uint256 beforeRefinanceOwnerBalance = assetBalance(owner, address(daiToken));

        LoanAuction memory loanAuction = tryToRefinanceByLender(newOffer, "should work");

        uint256 afterRefinanceOwnerBalance = assetBalance(owner, address(daiToken));
        uint256 afterRefinanceOwnerBalancePlusOne = assetBalancePlusOneCToken(
            owner,
            address(daiToken)
        );

        assertCloseEnough(
            beforeRefinanceOwnerBalance +
                ((loanAuction.amountDrawn * lending.termGriefingPremiumBps()) / MAX_BPS) +
                loanAuction.accumulatedPaidProtocolInterest,
            afterRefinanceOwnerBalance,
            afterRefinanceOwnerBalancePlusOne
        );
    }

    function test_unit_refinanceByLender_worksWith0ExpectedTimestamp() public {
        assertEq(lending.defaultRefinancePremiumBps(), 25);

        Offer memory offer = offerStructFromFields(
            defaultFixedFuzzedFieldsForFastUnitTesting,
            defaultFixedOfferFields
        );
        (, LoanAuction memory firstLoan) = createOfferAndTryToExecuteLoanByBorrower(
            offer,
            "should work"
        );

        // new offer from lender2 with +1 amount
        // will trigger term griefing and gas griefing
        defaultFixedOfferFields.creator = lender2;
        defaultFixedFuzzedFieldsForFastUnitTesting.duration =
            defaultFixedFuzzedFieldsForFastUnitTesting.duration +
            1; // make sure offer is better
        defaultFixedFuzzedFieldsForFastUnitTesting.floorTerm = false; // refinance can't be floor term
        defaultFixedFuzzedFieldsForFastUnitTesting.expiration = firstLoan.loanEndTimestamp - 1;
        Offer memory newOffer = offerStructFromFields(
            defaultFixedFuzzedFieldsForFastUnitTesting,
            defaultFixedOfferFields
        );

        vm.warp(firstLoan.loanEndTimestamp - 2);

        vm.startPrank(lender2);
        lending.refinanceByLender(newOffer, 0);
        vm.stopPrank();
        uint256 termGriefingToProtocol = (lending.termGriefingPremiumBps() *
            firstLoan.amountDrawn) / MAX_BPS;

        uint256 defaultPremiumToProtocol = (lending.defaultRefinancePremiumBps() *
            firstLoan.amountDrawn) / MAX_BPS;

        LoanAuction memory loanAuction = lending.getLoanAuction(
            newOffer.nftContractAddress,
            newOffer.nftId
        );

        uint256 protocolInterest = loanAuction.accumulatedPaidProtocolInterest +
            loanAuction.unpaidProtocolInterest;

        if (offer.asset == address(daiToken)) {
            assertBetween(
                protocolInterest + defaultPremiumToProtocol + termGriefingToProtocol,
                assetBalance(owner, address(daiToken)),
                assetBalancePlusOneCToken(owner, address(daiToken))
            );
        } else {
            assertBetween(
                protocolInterest + defaultPremiumToProtocol + termGriefingToProtocol,
                assetBalance(owner, ETH_ADDRESS),
                assetBalancePlusOneCToken(owner, ETH_ADDRESS)
            );
        }
    }
}
