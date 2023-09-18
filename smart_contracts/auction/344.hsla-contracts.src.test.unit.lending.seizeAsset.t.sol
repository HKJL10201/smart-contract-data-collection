// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";

contract TestSeizeAsset is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function _test_seizeAsset_simplest_case(FuzzedOfferFields memory fuzzed) private {
        uint256 initialTimestamp = block.timestamp;

        vm.assume(fuzzed.floorTerm == false);
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");

        // attempts to seize something lending doesn't know about should fail
        vm.startPrank(lender1);
        vm.expectRevert("00040"); // asset allow list
        lending.seizeAsset(offer.nftContractAddress, 123456);
        vm.stopPrank();

        // warp ahead 1 second *before* loan end
        vm.warp(initialTimestamp + offer.duration - 1);

        // attempt to seize results in revert (loan not expired)
        vm.startPrank(lender1);
        vm.expectRevert("00008"); // loan not expired
        lending.seizeAsset(offer.nftContractAddress, offer.nftId);
        vm.stopPrank();

        // warp to end of loan
        vm.warp(initialTimestamp + offer.duration);

        // still owned by borrower (in contract escrow)
        assertEq(mockNft.ownerOf(offer.nftId), address(lending));
        assertEq(lending.ownerOf(offer.nftContractAddress, offer.nftId), address(borrower1));

        // seize asset should work
        vm.startPrank(lender1);
        lending.seizeAsset(offer.nftContractAddress, offer.nftId);
        vm.stopPrank();

        // lender1 owns NFT after seize
        assertEq(mockNft.ownerOf(offer.nftId), address(lender1));
        assertEq(lending.ownerOf(offer.nftContractAddress, offer.nftId), address(0));
    }

    function test_fuzz_seizeAsset_simplest_case(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_seizeAsset_simplest_case(fuzzed);
    }

    function test_unit_seizeAsset_simplest_case() public {
        FuzzedOfferFields memory fixedForSpeed = defaultFixedFuzzedFieldsForFastUnitTesting;
        _test_seizeAsset_simplest_case(fixedForSpeed);
    }

    function _test_seizeAsset_refinance_before_expiration(FuzzedOfferFields memory fuzzed) private {
        uint256 initialTimestamp = block.timestamp;

        // create loan
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");

        // warp ahead 1 second *before* loan end
        vm.warp(initialTimestamp + offer.duration - 1);

        // attempt to seize results in revert (loan not expired)
        vm.startPrank(lender1);
        vm.expectRevert("00008"); // loan not expired
        lending.seizeAsset(offer.nftContractAddress, offer.nftId);
        vm.stopPrank();

        // set up refinance
        defaultFixedOfferFields.creator = lender2;
        fuzzed.duration = fuzzed.duration + 1; // make sure offer is better
        fuzzed.floorTerm = false; // refinance can't be floor term
        fuzzed.expiration = uint32(block.timestamp) + 1;
        fuzzed.amount = offer.amount;

        Offer memory newOffer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        tryToRefinanceByLender(newOffer, "should work");

        // warp ahead to end of refinance
        vm.warp(initialTimestamp + newOffer.duration);

        // borrower still owns NFT (in contract escrow)
        assertEq(mockNft.ownerOf(offer.nftId), address(lending));
        assertEq(lending.ownerOf(offer.nftContractAddress, offer.nftId), address(borrower1));

        // lender1 triggers seizure, but lender2 receives it since they have active loan
        vm.startPrank(lender1);
        lending.seizeAsset(offer.nftContractAddress, offer.nftId);
        vm.stopPrank();

        // lender2 owns NFT
        assertEq(mockNft.ownerOf(offer.nftId), address(lender2));
        assertEq(lending.ownerOf(offer.nftContractAddress, offer.nftId), address(0));
    }

    function test_fuzz_seizeAsset_refinance_before_expiration(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_seizeAsset_refinance_before_expiration(fuzzed);
    }

    function test_unit_seizeAsset_refinance_before_expiration() public {
        FuzzedOfferFields memory fixedForSpeed = defaultFixedFuzzedFieldsForFastUnitTesting;
        _test_seizeAsset_refinance_before_expiration(fixedForSpeed);
    }

    function _test_seizeAsset_CANNOT_if_loan_repaid(FuzzedOfferFields memory fuzzed) private {
        uint256 initialTimestamp = block.timestamp;

        // create loan
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");

        // warp ahead to end of loan
        vm.warp(initialTimestamp + offer.duration);

        LoanAuction memory loanAuction = lending.getLoanAuction(
            offer.nftContractAddress,
            offer.nftId
        );

        (uint256 accruedLenderInterest, uint256 accruedProtocolInterest) = lending
            .calculateInterestAccrued(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId
            );

        uint256 interestThreshold = (uint256(loanAuction.amountDrawn) *
            lending.gasGriefingPremiumBps()) / MAX_BPS;

        uint256 interestDelta = 0;

        if (interestThreshold > accruedLenderInterest) {
            interestDelta = interestThreshold - accruedLenderInterest;
        }

        uint256 protocolInterest = loanAuction.accumulatedPaidProtocolInterest +
            loanAuction.unpaidProtocolInterest +
            accruedProtocolInterest;

        // borrower still owns NFT (in contract escrow)
        assertEq(mockNft.ownerOf(offer.nftId), address(lending));
        assertEq(lending.ownerOf(offer.nftContractAddress, offer.nftId), address(borrower1));

        // borrower repays loan
        mintDai(
            borrower1,
            (offer.interestRatePerSecond * offer.duration) + protocolInterest + interestDelta
        );

        vm.startPrank(borrower1);
        if (offer.asset == address(daiToken)) {
            daiToken.approve(address(liquidity), ~uint256(0));
            lending.repayLoan(offer.nftContractAddress, offer.nftId);
        } else {
            vm.deal(
                borrower1,
                offer.amount +
                    (offer.interestRatePerSecond * offer.duration) +
                    protocolInterest +
                    interestDelta
            );
            lending.repayLoan{
                value: offer.amount +
                    (offer.interestRatePerSecond * offer.duration) +
                    protocolInterest +
                    interestDelta
            }(offer.nftContractAddress, offer.nftId);
        }
        vm.stopPrank();
        // attempt to seize results in revert
        vm.startPrank(lender1);
        vm.expectRevert("00040");
        lending.seizeAsset(offer.nftContractAddress, offer.nftId);
        vm.stopPrank();

        // borrower in possession of NFT
        assertEq(mockNft.ownerOf(offer.nftId), address(borrower1));
        assertEq(lending.ownerOf(offer.nftContractAddress, offer.nftId), address(0));
    }

    function test_fuzz_seizeAsset_CANNOT_if_loan_repaid(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_seizeAsset_CANNOT_if_loan_repaid(fuzzed);
    }

    function test_unit_seizeAsset_CANNOT_if_loan_repaid() public {
        FuzzedOfferFields memory fixedForSpeed = defaultFixedFuzzedFieldsForFastUnitTesting;
        _test_seizeAsset_CANNOT_if_loan_repaid(fixedForSpeed);
    }

    function test_unit_seizeAsset_3rdParty_works() public {
        uint256 initialTimestamp = block.timestamp;

        Offer memory offer = offerStructFromFields(
            defaultFixedFuzzedFieldsForFastUnitTesting,
            defaultFixedOfferFields
        );
        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");

        // warp to end of loan
        vm.warp(initialTimestamp + offer.duration);

        // still owned by borrower (in contract escrow)
        assertEq(mockNft.ownerOf(offer.nftId), address(lending));
        assertEq(lending.ownerOf(offer.nftContractAddress, offer.nftId), address(borrower1));

        // seize asset by other lendershould work
        vm.startPrank(lender2);
        lending.seizeAsset(offer.nftContractAddress, offer.nftId);
        vm.stopPrank();

        // lender1 owns NFT after seize
        assertEq(mockNft.ownerOf(offer.nftId), address(lender1));
        assertEq(lending.ownerOf(offer.nftContractAddress, offer.nftId), address(0));
    }
}
