// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract ContractThatCannotReceiveEth is ERC721HolderUpgradeable {
    receive() external payable {
        revert("no Eth!");
    }
}

contract TestExecuteLoanByBorrower is Test, OffersLoansRefinancesFixtures {
    ContractThatCannotReceiveEth private contractThatCannotReceiveEth;

    function setUp() public override {
        super.setUp();

        contractThatCannotReceiveEth = new ContractThatCannotReceiveEth();
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

    function _test_executeLoanByBorrower_simplest_case(FuzzedOfferFields memory fuzzed) private {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");
        assertionsForExecutedLoan(offer);
    }

    function test_fuzz_executeLoanByBorrower_simplest_case(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_executeLoanByBorrower_simplest_case(fuzzed);
    }

    function test_unit_executeLoanByBorrower_simplest_case_dai() public {
        FuzzedOfferFields memory fixedForSpeed = defaultFixedFuzzedFieldsForFastUnitTesting;
        fixedForSpeed.randomAsset = 0; // DAI
        _test_executeLoanByBorrower_simplest_case(fixedForSpeed);
    }

    function test_unit_executeLoanByBorrower_simplest_case_eth() public {
        FuzzedOfferFields memory fixedForSpeed = defaultFixedFuzzedFieldsForFastUnitTesting;
        fixedForSpeed.randomAsset = 1; // ETH
        _test_executeLoanByBorrower_simplest_case(fixedForSpeed);
    }

    function _test_executeLoanByBorrower_events(FuzzedOfferFields memory fuzzed) private {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        LoanAuction memory loanAuction = lending.getLoanAuction(
            offer.nftContractAddress,
            offer.nftId
        );

        vm.expectEmit(true, true, false, false);
        emit LoanExecuted(offer.nftContractAddress, offer.nftId, loanAuction);

        createOfferAndTryToExecuteLoanByBorrower(offer, "should work");
    }

    function test_unit_executeLoanByBorrower_events() public {
        _test_executeLoanByBorrower_events(defaultFixedFuzzedFieldsForFastUnitTesting);
    }

    function test_fuzz_executeLoanByBorrower_events(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_executeLoanByBorrower_events(fuzzed);
    }

    function _test_cannot_executeLoanByBorrower_if_offer_expired(FuzzedOfferFields memory fuzzed)
        private
    {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        createOffer(offer, lender1);
        vm.warp(offer.expiration);
        approveLending(offer);
        tryToExecuteLoanByBorrower(offer, "00010");
    }

    function test_fuzz_cannot_executeLoanByBorrower_if_offer_expired(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_cannot_executeLoanByBorrower_if_offer_expired(fuzzed);
    }

    function test_unit_cannot_executeLoanByBorrower_if_offer_expired() public {
        _test_cannot_executeLoanByBorrower_if_offer_expired(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_executeLoanByBorrower_if_asset_not_in_allow_list(
        FuzzedOfferFields memory fuzzed
    ) public {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        createOffer(offer, lender1);
        vm.startPrank(owner);
        liquidity.setCAssetAddress(offer.asset, address(0));
        vm.stopPrank();
        tryToExecuteLoanByBorrower(offer, "00040");
    }

    function test_fuzz_cannot_executeLoanByBorrower_if_asset_not_in_allow_list(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_cannot_executeLoanByBorrower_if_asset_not_in_allow_list(fuzzed);
    }

    function test_unit_cannot_executeLoanByBorrower_if_asset_not_in_allow_list() public {
        _test_cannot_executeLoanByBorrower_if_asset_not_in_allow_list(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_executeLoanByBorrower_if_offer_not_created(
        FuzzedOfferFields memory fuzzed
    ) private {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        // notice conspicuous absence of createOffer here
        approveLending(offer);
        tryToExecuteLoanByBorrower(offer, "00022");
    }

    function test_fuzz_cannot_executeLoanByBorrower_if_offer_not_created(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_cannot_executeLoanByBorrower_if_offer_not_created(fuzzed);
    }

    function test_unit_cannot_executeLoanByBorrower_if_offer_not_created() public {
        _test_cannot_executeLoanByBorrower_if_offer_not_created(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_executeLoanByBorrower_if_dont_own_nft(FuzzedOfferFields memory fuzzed)
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

    function test_fuzz_cannot_executeLoanByBorrower_if_dont_own_nft(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_cannot_executeLoanByBorrower_if_dont_own_nft(fuzzed);
    }

    function test_unit_cannot_executeLoanByBorrower_if_dont_own_nft() public {
        _test_cannot_executeLoanByBorrower_if_dont_own_nft(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_executeLoanByBorrower_if_not_enough_tokens(
        FuzzedOfferFields memory fuzzed
    ) private {
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

    function test_fuzz_cannot_executeLoanByBorrower_if_not_enough_tokens(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_cannot_executeLoanByBorrower_if_not_enough_tokens(fuzzed);
    }

    function test_unit_cannot_executeLoanByBorrower_if_not_enough_tokens() public {
        _test_cannot_executeLoanByBorrower_if_not_enough_tokens(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_executeLoanByBorrower_if_underlying_transfer_fails(
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

    function test_fuzz_cannot_executeLoanByBorrower_if_underlying_transfer_fails(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_cannot_executeLoanByBorrower_if_underlying_transfer_fails(fuzzed);
    }

    function test_unit_cannot_executeLoanByBorrower_if_underlying_transfer_fails() public {
        _test_cannot_executeLoanByBorrower_if_underlying_transfer_fails(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_executeLoanByBorrower_if_eth_transfer_fails(
        FuzzedOfferFields memory fuzzed
    ) private {
        fuzzed.randomAsset = 1; // ETH
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        // give NFT to contract
        vm.startPrank(borrower1);
        mockNft.safeTransferFrom(borrower1, address(contractThatCannotReceiveEth), 1);
        vm.stopPrank();

        // set borrower1 to contract
        borrower1 = payable(address(contractThatCannotReceiveEth));

        createOfferAndTryToExecuteLoanByBorrower(
            offer,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function test_fuzz_cannot_executeLoanByBorrower_if_eth_transfer_fails(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_cannot_executeLoanByBorrower_if_eth_transfer_fails(fuzzed);
    }

    function test_unit_cannot_executeLoanByBorrower_if_eth_transfer_fails() public {
        _test_cannot_executeLoanByBorrower_if_eth_transfer_fails(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_executeLoanByBorrower_if_borrower_offer(FuzzedOfferFields memory fuzzed)
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

    function test_fuzz_executeLoanByBorrower_if_borrower_offer(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_cannot_executeLoanByBorrower_if_borrower_offer(fuzzed);
    }

    function test_unit_executeLoanByBorrower_if_borrower_offer() public {
        _test_cannot_executeLoanByBorrower_if_borrower_offer(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_executeLoanByBorrower_if_loan_active(FuzzedOfferFields memory fuzzed)
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

    function test_fuzz_executeLoanByBorrower_if_loan_active(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        _test_cannot_executeLoanByBorrower_if_loan_active(fuzzed);
    }

    function test_unit_executeLoanByBorrower_if_loan_active() public {
        _test_cannot_executeLoanByBorrower_if_loan_active(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_executeLoanByBorrower_notFloorTerm_mismatchNftIds(
        FuzzedOfferFields memory fuzzed
    ) private {
        defaultFixedOfferFields.lenderOffer = true;
        defaultFixedOfferFields.nftId = 2;
        fuzzed.floorTerm = false;

        Offer memory offer1 = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        createOffer(offer1, lender1);

        bytes32 offerHash = offers.getOfferHash(offer1);

        Offer memory offer2 = offer1;

        offer2.nftId = 1;

        createOffer(offer2, lender1);

        vm.startPrank(borrower1);
        mockNft.approve(address(lending), 1);

        vm.expectRevert("00022");
        lending.executeLoanByBorrower(offer1.nftContractAddress, 1, offerHash, offer1.floorTerm);
        vm.stopPrank();
    }

    function test_fuzz_executeLoanByBorrower_notFloorTerm_mismatchNftIds(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_cannot_executeLoanByBorrower_notFloorTerm_mismatchNftIds(fuzzed);
    }

    function test_unit_executeLoanByBorrower_notFloorTerm_mismatchNftIds() public {
        _test_cannot_executeLoanByBorrower_notFloorTerm_mismatchNftIds(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_executeLoanByBorrower_sanctioned_address_borrower(
        FuzzedOfferFields memory fuzzed
    ) private {
        defaultFixedOfferFields.lenderOffer = true;
        defaultFixedOfferFields.nftId = 3;

        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        createOffer(offer, lender1);

        bytes32 offerHash = offers.getOfferHash(offer);

        vm.startPrank(SANCTIONED_ADDRESS);
        mockNft.approve(address(lending), 3);

        vm.expectRevert("00017");
        lending.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
        vm.stopPrank();
    }

    function test_fuzz_executeLoanByBorrower_sanctioned_address_borrower(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_cannot_executeLoanByBorrower_sanctioned_address_borrower(fuzzed);
    }

    function test_unit_executeLoanByBorrower_sanctioned_address_borrower() public {
        _test_cannot_executeLoanByBorrower_sanctioned_address_borrower(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function _test_cannot_executeLoanByBorrower_sanctioned_address_lender(
        FuzzedOfferFields memory fuzzed
    ) private {
        vm.startPrank(owner);
        liquidity.pauseSanctions();
        vm.stopPrank();

        fuzzed.randomAsset = 0;

        if (integration) {
            vm.startPrank(daiWhale);
            daiToken.transfer(SANCTIONED_ADDRESS, defaultDaiLiquiditySupplied / 2);
            vm.stopPrank();
        } else {
            vm.startPrank(SANCTIONED_ADDRESS);
            daiToken.mint(SANCTIONED_ADDRESS, defaultDaiLiquiditySupplied / 2);
            vm.stopPrank();
        }

        vm.startPrank(SANCTIONED_ADDRESS);
        daiToken.approve(address(liquidity), defaultDaiLiquiditySupplied / 2);

        liquidity.supplyErc20(address(daiToken), defaultDaiLiquiditySupplied / 2);
        vm.stopPrank();

        defaultFixedOfferFields.lenderOffer = true;

        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

        createOffer(offer, SANCTIONED_ADDRESS);

        vm.startPrank(owner);
        liquidity.unpauseSanctions();
        vm.stopPrank();

        bytes32 offerHash = offers.getOfferHash(offer);

        vm.startPrank(borrower1);
        mockNft.approve(address(lending), 1);

        vm.expectRevert("00017");
        lending.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
        vm.stopPrank();
    }

    function test_fuzz_executeLoanByBorrower_sanctioned_address_lender(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        _test_cannot_executeLoanByBorrower_sanctioned_address_lender(fuzzed);
    }

    function test_unit_executeLoanByBorrower_sanctioned_address_lender() public {
        _test_cannot_executeLoanByBorrower_sanctioned_address_lender(
            defaultFixedFuzzedFieldsForFastUnitTesting
        );
    }

    function test_fuzz_executeLoanByBorrower_floorTermCounter(FuzzedOfferFields memory fuzzed)
        public
        validateFuzzedOfferFields(fuzzed)
    {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        offer.floorTerm = true;
        offer.creator = lender1;
        offer.floorTermLimit = 2;

        vm.startPrank(lender1);
        bytes32 offerHash = offers.createOffer(offer);
        vm.stopPrank();

        uint64 count1 = offers.getFloorOfferCount(offerHash);
        assertEq(count1, 0);

        approveLending(offer);
        tryToExecuteLoanByBorrower(offer, "should work");

        uint64 count2 = offers.getFloorOfferCount(offerHash);
        assertEq(count2, 1);

        vm.startPrank(borrower2);
        mockNft.approve(address(lending), 2);
        lending.executeLoanByBorrower(offer.nftContractAddress, 2, offerHash, offer.floorTerm);
        vm.stopPrank();
    }

    function test_fuzz_cannot_executeLoanByBorrower_floorTermCounter(
        FuzzedOfferFields memory fuzzed
    ) public validateFuzzedOfferFields(fuzzed) {
        Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
        offer.floorTerm = true;
        offer.creator = lender1;

        vm.startPrank(lender1);
        bytes32 offerHash = offers.createOffer(offer);
        vm.stopPrank();

        uint64 count1 = offers.getFloorOfferCount(offerHash);
        assertEq(count1, 0);

        approveLending(offer);
        tryToExecuteLoanByBorrower(offer, "should work");

        vm.startPrank(borrower2);
        mockNft.approve(address(lending), 2);
        vm.expectRevert("00051");
        lending.executeLoanByBorrower(offer.nftContractAddress, 2, offerHash, offer.floorTerm);
        vm.stopPrank();
    }
}
