// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/LenderLiquidityFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

import "../../common/BaseTest.sol";

uint256 constant MAX_BPS = 10_000;
uint256 constant MAX_FEE = 1_000;

// Note: need "sign" function from BaseTest for signOffer below
contract OffersLoansRefinancesFixtures is
    Test,
    BaseTest,
    IOffersStructs,
    ILendingEvents,
    ILendingStructs,
    LenderLiquidityFixtures
{
    struct FuzzedOfferFields {
        bool floorTerm;
        uint128 amount;
        uint96 interestRatePerSecond;
        uint32 duration;
        uint32 expiration;
        uint8 randomAsset; // asset = randomAsset % 2 == 0 ? DAI : ETH
    }

    struct FixedOfferFields {
        bool fixedTerms;
        address creator;
        bool lenderOffer;
        uint256 nftId;
        address nftContractAddress;
        uint64 floorTermLimit;
    }

    FixedOfferFields internal defaultFixedOfferFields;
    FixedOfferFields internal defaultFixedBorrowerOfferFields;

    FuzzedOfferFields internal defaultFixedFuzzedFieldsForFastUnitTesting;

    function setUp() public virtual override {
        super.setUp();

        // these fields are fixed, not fuzzed
        // but specific fields can be overridden in tests
        defaultFixedOfferFields = FixedOfferFields({
            fixedTerms: false,
            creator: lender1,
            lenderOffer: true,
            nftContractAddress: address(mockNft),
            nftId: 1,
            floorTermLimit: 1
        });

        defaultFixedBorrowerOfferFields = FixedOfferFields({
            fixedTerms: false,
            creator: borrower1,
            lenderOffer: false,
            nftContractAddress: address(mockNft),
            nftId: 1,
            floorTermLimit: 1
        });

        uint8 randomAsset = 0; // 0 == DAI, 1 == ETH

        // in addition to fuzz tests, we have fast unit tests
        // using these default values instead of fuzzing
        defaultFixedFuzzedFieldsForFastUnitTesting = FuzzedOfferFields({
            floorTerm: false,
            amount: randomAsset % 2 == 0 ? 10 * uint128(10**daiToken.decimals()) : 1 ether,
            interestRatePerSecond: randomAsset % 2 == 0
                ? uint96(10**daiToken.decimals() / 10000)
                : 10**6,
            duration: 1 weeks,
            expiration: uint32(block.timestamp) + 1 days,
            randomAsset: randomAsset
        });
    }

    modifier validateFuzzedOfferFields(FuzzedOfferFields memory fuzzed) {
        // -10 ether to give refinancing lender some wiggle room for fees
        if (fuzzed.randomAsset % 2 == 0) {
            vm.assume(fuzzed.amount > ~uint32(0));
            vm.assume(fuzzed.amount < (defaultDaiLiquiditySupplied * 50) / 100);
        } else {
            vm.assume(fuzzed.amount > ~uint32(0));
            vm.assume(fuzzed.amount < (defaultEthLiquiditySupplied * 50) / 100);
        }

        vm.assume(fuzzed.duration > 1 days);
        // to avoid overflow when loanAuction.loanEndTimestamp = _currentTimestamp32() + offer.duration;
        vm.assume(fuzzed.duration < (~uint32(0) - block.timestamp));
        vm.assume(fuzzed.expiration > block.timestamp);
        // to avoid "Division or m  odulo by 0"
        vm.assume(fuzzed.interestRatePerSecond > 0);
        // don't want interest to be too much for refinancing lender
        vm.assume(fuzzed.interestRatePerSecond < (fuzzed.randomAsset % 2 == 0 ? 100 : 10**13));
        _;
    }

    function offerStructFromFields(
        FuzzedOfferFields memory fuzzed,
        FixedOfferFields memory fixedFields
    ) internal view returns (Offer memory) {
        address asset = fuzzed.randomAsset % 2 == 0 ? address(daiToken) : address(ETH_ADDRESS);

        bool isAmountEnough;

        if (fuzzed.randomAsset % 2 == 0) {
            isAmountEnough = fuzzed.amount >= 10 * uint128(10**daiToken.decimals());
        } else {
            isAmountEnough = fuzzed.amount >= 250000000;
        }

        return
            Offer({
                creator: fixedFields.creator,
                lenderOffer: fixedFields.lenderOffer,
                nftId: fixedFields.nftId,
                nftContractAddress: fixedFields.nftContractAddress,
                fixedTerms: fixedFields.fixedTerms,
                asset: asset,
                floorTerm: fuzzed.floorTerm,
                interestRatePerSecond: fuzzed.interestRatePerSecond,
                amount: isAmountEnough
                    ? fuzzed.amount
                    : (
                        fuzzed.randomAsset % 2 == 0
                            ? 10 * uint128(10**daiToken.decimals())
                            : 250000000
                    ),
                duration: fuzzed.duration,
                expiration: fuzzed.expiration,
                floorTermLimit: fixedFields.floorTermLimit
            });
    }

    function createOffer(Offer memory offer, address lender) internal returns (Offer memory) {
        vm.startPrank(lender);
        offer.creator = lender;
        bytes32 offerHash = offers.createOffer(offer);
        vm.stopPrank();
        return offers.getOffer(offer.nftContractAddress, offer.nftId, offerHash, offer.floorTerm);
    }

    function createBorrowerOffer(Offer memory offer) internal returns (Offer memory) {
        vm.startPrank(offer.creator);
        bytes32 offerHash = offers.createOffer(offer);
        vm.stopPrank();
        return offers.getOffer(offer.nftContractAddress, offer.nftId, offerHash, offer.floorTerm);
    }

    function approveLending(Offer memory offer) internal {
        vm.startPrank(borrower1);
        mockNft.approve(address(lending), offer.nftId);
        vm.stopPrank();
    }

    function tryToExecuteLoanByBorrower(Offer memory offer, bytes memory errorCode)
        internal
        returns (LoanAuction memory)
    {
        vm.startPrank(borrower1);
        bytes32 offerHash = offers.getOfferHash(offer);

        if (bytes16(errorCode) != bytes16("should work")) {
            vm.expectRevert(errorCode);
        }

        lending.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
        vm.stopPrank();

        return lending.getLoanAuction(offer.nftContractAddress, offer.nftId);
    }

    function tryToExecuteLoanByLender(Offer memory offer, bytes memory errorCode)
        internal
        returns (LoanAuction memory)
    {
        vm.startPrank(lender1);

        bytes32 offerHash = offers.getOfferHash(offer);

        if (bytes16(errorCode) != bytes16("should work")) {
            vm.expectRevert(errorCode);
        }

        lending.executeLoanByLender(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
        vm.stopPrank();

        return lending.getLoanAuction(offer.nftContractAddress, offer.nftId);
    }

    function createOfferAndTryToExecuteLoanByBorrower(Offer memory offer, bytes memory errorCode)
        internal
        returns (Offer memory, LoanAuction memory)
    {
        Offer memory offerCreated = createOffer(offer, lender1);

        approveLending(offer);
        LoanAuction memory loan = tryToExecuteLoanByBorrower(offer, errorCode);
        return (offerCreated, loan);
    }

    function createOfferAndTryToExecuteLoanByLender(Offer memory offer, bytes memory errorCode)
        internal
        returns (Offer memory, LoanAuction memory)
    {
        Offer memory offerCreated = createBorrowerOffer(offer);
        approveLending(offer);
        LoanAuction memory loan = tryToExecuteLoanByLender(offer, errorCode);
        return (offerCreated, loan);
    }

    function tryToRefinanceLoanByBorrower(Offer memory newOffer, bytes memory errorCode) internal {
        vm.startPrank(lender2);
        bytes32 offerHash = offers.createOffer(newOffer);
        vm.stopPrank();

        if (bytes16(errorCode) != bytes16("should work")) {
            vm.expectRevert(errorCode);
        }

        vm.startPrank(borrower1);
        lending.refinanceByBorrower(
            newOffer.nftContractAddress,
            newOffer.nftId,
            newOffer.floorTerm,
            offerHash,
            lending.getLoanAuction(address(mockNft), 1).lastUpdatedTimestamp
        );
        vm.stopPrank();
    }

    function tryToRefinanceByLender(Offer memory newOffer, bytes memory errorCode)
        internal
        returns (LoanAuction memory)
    {
        vm.startPrank(lender2);

        if (bytes16(errorCode) != bytes16("should work")) {
            vm.expectRevert(errorCode);
        }
        lending.refinanceByLender(
            newOffer,
            lending.getLoanAuction(address(mockNft), 1).lastUpdatedTimestamp
        );
        vm.stopPrank();
        return lending.getLoanAuction(newOffer.nftContractAddress, newOffer.nftId);
    }

    function assetBalance(address account, address asset) internal returns (uint256) {
        address cAsset = liquidity.assetToCAsset(asset);

        uint256 cTokens = liquidity.getCAssetBalance(account, address(cAsset));

        return liquidity.cAssetAmountToAssetAmount(address(cAsset), cTokens);
    }

    function assetBalancePlusOneCToken(address account, address asset) internal returns (uint256) {
        address cAsset = liquidity.assetToCAsset(asset);

        uint256 cTokens = liquidity.getCAssetBalance(account, address(cAsset)) + 1;

        return liquidity.cAssetAmountToAssetAmount(address(cAsset), cTokens);
    }

    function signOffer(uint256 signerPrivateKey, Offer memory offer) public returns (bytes memory) {
        // This is the EIP712 signed hash
        bytes32 offerHash = offers.getOfferHash(offer);

        return sign(signerPrivateKey, offerHash);
    }
}
