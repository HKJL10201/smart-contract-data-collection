// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Upgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";

contract TestExecuteLoanByBorrower is Test, OffersLoansRefinancesFixtures {
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

        // will trigger gas griefing (but not term griefing with borrower refinance)
        defaultFixedOfferFields.creator = lender2;
        fuzzed.duration = fuzzed.duration + 1; // make sure offer is better
        fuzzed.floorTerm = false; // refinance can't be floor term
        fuzzed.expiration = uint32(block.timestamp) + secondsBeforeRefinance + 1;
        fuzzed.amount = uint128(
            offer.amount +
                (offer.interestRatePerSecond * secondsBeforeRefinance) +
                interestShortfall +
                ((amountDrawn * lending.protocolInterestBps()) / 10_000) +
                ((amountDrawn * lending.originationPremiumBps()) / 10_000)
        );

        Offer memory newOffer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        uint256 beforeRefinanceLenderBalance = assetBalance(lender1, address(daiToken));

        if (offer.asset == address(daiToken)) {
            beforeRefinanceLenderBalance = assetBalance(lender1, address(daiToken));
        } else {
            beforeRefinanceLenderBalance = assetBalance(lender1, ETH_ADDRESS);
        }

        tryToRefinanceLoanByBorrower(newOffer, "should work");

        assertionsForExecutedRefinance(
            offer,
            amountDrawn,
            secondsBeforeRefinance,
            interestShortfall,
            beforeRefinanceLenderBalance
        );
    }

    function refinanceByLenderSetup(FuzzedOfferFields memory fuzzed, uint16 secondsBeforeRefinance)
        private
    {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");

        assertionsForExecutedLoan(offer);

        vm.warp(block.timestamp + secondsBeforeRefinance);

        defaultFixedOfferFields.creator = lender2;
        fuzzed.duration = fuzzed.duration + 1; // make sure offer is better
        fuzzed.floorTerm = false; // refinance can't be floor term
        fuzzed.expiration = uint32(block.timestamp) + secondsBeforeRefinance + 1;
        fuzzed.amount = offer.amount * 3;

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

        assertEq(loanAuction.accumulatedLenderInterest, lenderInterest);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, protocolInterest);
        assertEq(loanAuction.slashableLenderInterest, 0);
        // lenderRefi is true
        assertFalse(!lending.getLoanAuction(address(mockNft), 1).lenderRefi);
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
        uint16 secondsBeforeRefinance,
        uint256 interestShortfall,
        uint256 beforeRefinanceLenderBalance
    ) private {
        // lender1 has money
        if (offer.asset == address(daiToken)) {
            assertBetween(
                beforeRefinanceLenderBalance +
                    amountDrawn +
                    (offer.interestRatePerSecond * secondsBeforeRefinance) +
                    interestShortfall +
                    ((uint256(amountDrawn) * lending.originationPremiumBps()) / MAX_BPS),
                assetBalance(lender1, address(daiToken)),
                assetBalancePlusOneCToken(lender1, address(daiToken))
            );
        } else {
            assertBetween(
                beforeRefinanceLenderBalance +
                    amountDrawn +
                    (offer.interestRatePerSecond * secondsBeforeRefinance) +
                    interestShortfall +
                    ((uint256(amountDrawn) * lending.originationPremiumBps()) / MAX_BPS),
                assetBalance(lender1, ETH_ADDRESS),
                assetBalancePlusOneCToken(lender1, ETH_ADDRESS)
            );
        }
    }

    function test_fuzz_refinanceByBorrower(
        FuzzedOfferFields memory fuzzedOffer,
        uint16 secondsBeforeRefinance,
        uint16 gasGriefingPremiumBps,
        uint16 protocolInterestBps
    ) public validateFuzzedOfferFields(fuzzedOffer) {
        vm.assume(gasGriefingPremiumBps <= MAX_FEE);
        vm.assume(protocolInterestBps <= MAX_FEE);
        vm.startPrank(owner);
        lending.updateProtocolInterestBps(protocolInterestBps);
        lending.updateGasGriefingPremiumBps(gasGriefingPremiumBps);
        vm.stopPrank();
        refinanceSetup(fuzzedOffer, secondsBeforeRefinance);
    }

    function test_unit_refinanceByBorrower_creates_slashable_interest() public {
        // refinance by lender
        refinanceByLenderSetup(defaultFixedFuzzedFieldsForFastUnitTesting, 12 hours);

        // 12 hours
        vm.warp(block.timestamp + 1 hours);

        // set up refinance by borrower
        FuzzedOfferFields memory fuzzed = defaultFixedFuzzedFieldsForFastUnitTesting;

        defaultFixedOfferFields.creator = lender3;
        fuzzed.duration = fuzzed.duration + 1; // make sure offer is better
        fuzzed.floorTerm = false; // refinance can't be floor term
        fuzzed.expiration = uint32(block.timestamp) + 12 hours + 1;
        fuzzed.amount = uint128(
            10 * uint128(10**daiToken.decimals()) + 10 * uint128(10**daiToken.decimals())
        );

        Offer memory newOffer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        vm.startPrank(lender3);
        bytes32 offerHash = offers.createOffer(newOffer);
        vm.stopPrank();

        // refinance by borrower
        vm.startPrank(borrower1);
        lending.refinanceByBorrower(
            newOffer.nftContractAddress,
            newOffer.nftId,
            newOffer.floorTerm,
            offerHash,
            lending.getLoanAuction(address(mockNft), 1).lastUpdatedTimestamp
        );
        vm.stopPrank();

        // brand new lender after refinance means slashable should = 0
        assertEq(lending.getLoanAuction(address(mockNft), 1).slashableLenderInterest, 0);
        // lenderRefi is false
        assertFalse(lending.getLoanAuction(address(mockNft), 1).lenderRefi);
    }

    // At one point (~ Jul 20, 2022) in refinanceByBorrower, slashable interest
    // was being added to what was owed to the protocol, as opposed to what was owed to the lender
    // The following regression test will fail if this bug is present,
    // but pass if it's fixed
    function test_unit_refinanceByBorrower_gives_slashable_interest_to_refinanced_lender() public {
        uint256 beforeLenderBalance = assetBalance(lender2, address(daiToken));

        // refinance by lender2
        refinanceByLenderSetup(defaultFixedFuzzedFieldsForFastUnitTesting, 12 hours);

        // 12 hours
        vm.warp(block.timestamp + 12 hours);

        // set up refinance by borrower
        FuzzedOfferFields memory fuzzed = defaultFixedFuzzedFieldsForFastUnitTesting;

        defaultFixedOfferFields.creator = lender3;
        fuzzed.duration = fuzzed.duration;
        fuzzed.floorTerm = false; // refinance can't be floor term
        fuzzed.expiration = uint32(block.timestamp) + 12 hours + 1;
        fuzzed.amount = uint128(
            10 * uint128(10**daiToken.decimals()) + 10 * uint128(10**daiToken.decimals())
        );

        Offer memory newOffer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        vm.startPrank(lender3);
        bytes32 offerHash = offers.createOffer(newOffer);
        vm.stopPrank();

        uint256 amountDrawn = lending
            .getLoanAuction(newOffer.nftContractAddress, newOffer.nftId)
            .amountDrawn;

        // should be zero but keeping this in in case we convert this to a fuzz test
        uint256 interestShortfall = lending.checkSufficientInterestAccumulated(
            newOffer.nftContractAddress,
            newOffer.nftId
        );

        // refinance by borrower
        vm.startPrank(borrower1);
        lending.refinanceByBorrower(
            newOffer.nftContractAddress,
            newOffer.nftId,
            newOffer.floorTerm,
            offerHash,
            lending.getLoanAuction(address(mockNft), 1).lastUpdatedTimestamp
        );
        vm.stopPrank();

        assertCloseEnough(
            beforeLenderBalance +
                (newOffer.interestRatePerSecond * 12 hours) +
                interestShortfall -
                ((amountDrawn * lending.originationPremiumBps()) / 10_000),
            assetBalance(lender2, address(daiToken)),
            assetBalancePlusOneCToken(lender2, address(daiToken))
        );
    }

    function test_unit_CANNOT_refinanceByBorrower_unexpected_terms() public {
        // refinance by lender2
        refinanceByLenderSetup(defaultFixedFuzzedFieldsForFastUnitTesting, 12 hours);

        // 12 hours
        vm.warp(block.timestamp + 12 hours);

        // set up refinance by borrower
        FuzzedOfferFields memory fuzzed = defaultFixedFuzzedFieldsForFastUnitTesting;

        defaultFixedOfferFields.creator = lender3;
        fuzzed.duration = fuzzed.duration;
        fuzzed.floorTerm = false; // refinance can't be floor term
        fuzzed.expiration = uint32(block.timestamp) + 12 hours + 1;
        fuzzed.amount = uint128(
            10 * uint128(10**daiToken.decimals()) + 10 * uint128(10**daiToken.decimals())
        );

        Offer memory newOffer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        vm.startPrank(lender3);
        bytes32 offerHash = offers.createOffer(newOffer);
        vm.stopPrank();

        LoanAuction memory loanAuction = lending.getLoanAuction(
            newOffer.nftContractAddress,
            newOffer.nftId
        );

        // refinance by borrower
        vm.startPrank(borrower1);
        vm.expectRevert("00026");
        lending.refinanceByBorrower(
            newOffer.nftContractAddress,
            newOffer.nftId,
            newOffer.floorTerm,
            offerHash,
            (loanAuction.lastUpdatedTimestamp - 100)
        );
        vm.stopPrank();
    }

    function test_unit_CANNOT_refinanceByBorrower_loan_past_endTimestamp() public {
        // refinance by lender2
        refinanceByLenderSetup(defaultFixedFuzzedFieldsForFastUnitTesting, 12 hours);

        // set up refinance by borrower
        FuzzedOfferFields memory fuzzed = defaultFixedFuzzedFieldsForFastUnitTesting;

        defaultFixedOfferFields.creator = lender3;
        fuzzed.duration = fuzzed.duration;
        fuzzed.floorTerm = false; // refinance can't be floor term
        fuzzed.expiration = uint32(block.timestamp) + 12 hours + 1;
        fuzzed.amount = uint128(
            10 * uint128(10**daiToken.decimals()) + 10 * uint128(10**daiToken.decimals())
        );

        Offer memory newOffer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        vm.startPrank(lender3);
        bytes32 offerHash = offers.createOffer(newOffer);
        vm.stopPrank();

        LoanAuction memory loanAuction = lending.getLoanAuction(
            newOffer.nftContractAddress,
            newOffer.nftId
        );

        // 12 hours
        vm.warp(
            lending.getLoanAuction(newOffer.nftContractAddress, newOffer.nftId).loanEndTimestamp + 1
        );

        // refinance by borrower
        vm.startPrank(borrower1);
        vm.expectRevert("00009");
        lending.refinanceByBorrower(
            newOffer.nftContractAddress,
            newOffer.nftId,
            newOffer.floorTerm,
            offerHash,
            loanAuction.lastUpdatedTimestamp
        );
        vm.stopPrank();
    }

    // this test fails because refinanceByBorrower calls an additional internal function which passes the vm.expectRevert() statement.
    // however if this statement is commented out we see that the function does still fail with the proper "00017" error message.
    // function test_unit_CANNOT_refinanceByBorrower_sanctionedBorrower() public {
    //     vm.startPrank(owner);
    //     lending.updateProtocolInterestBps(100);
    //     lending.updateGasGriefingPremiumBps(25);
    //     lending.pauseSanctions();
    //     vm.stopPrank();

    //     Offer memory offer = offerStructFromFields(
    //         defaultFixedFuzzedFieldsForFastUnitTesting,
    //         defaultFixedOfferFields
    //     );

    //     offer.nftId = 3;

    //     vm.startPrank(offer.creator);
    //     bytes32 offerHash = offers.createOffer(offer);
    //     vm.stopPrank();

    //     vm.startPrank(SANCTIONED_ADDRESS);
    //     mockNft.approve(address(lending), offer.nftId);
    //     lending.executeLoanByBorrower(
    //         offer.nftContractAddress,
    //         offer.nftId,
    //         offerHash,
    //         offer.floorTerm
    //     );
    //     vm.stopPrank();

    //     // will trigger gas griefing (but not term griefing with borrower refinance)
    //     defaultFixedOfferFields.creator = lender2;

    //     Offer memory newOffer = offerStructFromFields(
    //         defaultFixedFuzzedFieldsForFastUnitTesting,
    //         defaultFixedOfferFields
    //     );

    //     newOffer.nftId = 3;

    //     vm.startPrank(lender2);
    //     bytes32 offerHash2 = offers.createOffer(newOffer);
    //     vm.stopPrank();

    //     vm.startPrank(owner);
    //     lending.unpauseSanctions();
    //     vm.stopPrank();

    //     vm.startPrank(SANCTIONED_ADDRESS);
    //     vm.expectRevert("00017");
    //     lending.refinanceByBorrower(
    //         newOffer.nftContractAddress,
    //         newOffer.nftId,
    //         newOffer.floorTerm,
    //         offerHash2,
    //         lending.getLoanAuction(address(mockNft), 3).lastUpdatedTimestamp
    //     );
    //     vm.stopPrank();
    // }
}
