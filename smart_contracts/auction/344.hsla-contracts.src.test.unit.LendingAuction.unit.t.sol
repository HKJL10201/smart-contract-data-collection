// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../../interfaces/compound/ICERC20.sol";
import "../../interfaces/compound/ICEther.sol";
import "../../Lending.sol";
import "../../Liquidity.sol";
import "../../Offers.sol";
import "../../SigLending.sol";
import "../../interfaces/niftyapes/lending/ILendingEvents.sol";
import "../../interfaces/niftyapes/offers/IOffersEvents.sol";

import "../common/BaseTest.sol";
import "../mock/CERC20Mock.sol";
import "../mock/CEtherMock.sol";
import "../mock/ERC20Mock.sol";
import "../mock/ERC721Mock.sol";

import "forge-std/Test.sol";

contract LendingAuctionUnitTest is
    BaseTest,
    ILendingEvents,
    ILendingStructs,
    IOffersEvents,
    IOffersStructs,
    ERC721HolderUpgradeable
{
    NiftyApesLending lendingAuction;
    NiftyApesOffers offersContract;
    NiftyApesLiquidity liquidityProviders;
    NiftyApesSigLending sigLendingAuction;
    ERC20Mock daiToken;
    CERC20Mock cDAIToken;
    CEtherMock cEtherToken;
    address compContractAddress = 0xbbEB7c67fa3cfb40069D19E598713239497A3CA5;

    ERC721Mock mockNft;

    bool acceptEth;

    address constant ZERO_ADDRESS = address(0);
    address constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address constant LENDER_1 = address(0x1010);
    address constant LENDER_2 = address(0x2020);
    address constant LENDER_3 = address(0x3030);
    address constant BORROWER_1 = address(0x101);
    address constant OWNER = address(0xFFFFFFFFFFFFFF);

    uint256 immutable SIGNER_PRIVATE_KEY_1 =
        0x60b919c82f0b4791a5b7c6a7275970ace1748759ebdaa4076d7eeed9dbcff3c3;
    address immutable SIGNER_1 = 0x503408564C50b43208529faEf9bdf9794c015d52;
    address immutable SIGNER_2 = 0x4a3A70D6Be2290f5F57Ac7E64b9A1B7695f5b0B3;

    address constant SANCTIONED_ADDRESS = 0x7FF9cFad3877F21d41Da833E2F775dB0569eE3D9;

    receive() external payable {
        require(acceptEth, "acceptEth");
    }

    function setUp() public {
        hevm.startPrank(OWNER);

        liquidityProviders = new NiftyApesLiquidity();
        liquidityProviders.initialize(compContractAddress);

        offersContract = new NiftyApesOffers();
        offersContract.initialize(address(liquidityProviders));

        sigLendingAuction = new NiftyApesSigLending();
        sigLendingAuction.initialize(address(offersContract));

        lendingAuction = new NiftyApesLending();
        lendingAuction.initialize(
            address(liquidityProviders),
            address(offersContract),
            address(sigLendingAuction)
        );

        liquidityProviders.updateLendingContractAddress(address(lendingAuction));

        offersContract.updateLendingContractAddress(address(lendingAuction));
        offersContract.updateSigLendingContractAddress(address(sigLendingAuction));

        sigLendingAuction.updateLendingContractAddress(address(lendingAuction));

        if (block.number == 1) {
            lendingAuction.pauseSanctions();
            liquidityProviders.pauseSanctions();
        }

        hevm.stopPrank();

        daiToken = new ERC20Mock();
        daiToken.initialize("USD Coin", "DAI");
        cDAIToken = new CERC20Mock();
        cDAIToken.initialize(daiToken);

        hevm.startPrank(OWNER);
        liquidityProviders.setCAssetAddress(address(daiToken), address(cDAIToken));
        liquidityProviders.setMaxCAssetBalance(address(cDAIToken), 2**256 - 1);

        cEtherToken = new CEtherMock();
        cEtherToken.initialize();
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );
        liquidityProviders.setMaxCAssetBalance(address(cEtherToken), 2**256 - 1);

        hevm.stopPrank();

        acceptEth = true;

        mockNft = new ERC721Mock();
        mockNft.initialize("BoredApe", "BAYC");

        mockNft.safeMint(address(this), 1);
        mockNft.approve(address(lendingAuction), 1);

        mockNft.safeMint(address(this), 2);
        mockNft.approve(address(lendingAuction), 2);
    }

    function signOffer(uint256 signerPrivateKey, Offer memory offer) public returns (bytes memory) {
        // This is the EIP712 signed hash
        bytes32 offerHash = offersContract.getOfferHash(offer);

        return sign(signerPrivateKey, offerHash);
    }

    function setupLoan() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444444,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function setupOwnerDAIBalance() public {
        // Also Note: assuming DAI has decimals 18 throughout
        // even though the real version has decimals 6
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 1 ether);
        daiToken.approve(address(liquidityProviders), 1 ether);
        liquidityProviders.supplyErc20(address(daiToken), 1 ether);

        // Lender 1 has 1 DAI
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            1 ether
        );

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 10_000_000_000,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 1 ether,
            duration: 365 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.stopPrank();

        // Borrower executes loan
        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        // Lender 1 has 1 fewer DAI, i.e., 0
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            0
        );

        // Protocol owner has 0
        // Would have more later if there were a term fee
        // But will still have 0 if there isn't
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(address(this), address(cDAIToken))
            ),
            0
        );

        // Warp ahead 10**6 seconds
        // 10**10 interest per second * 10**6 seconds = 10**16 interest
        // this is 0.01 of 10**18, which is over the gas griefing amount of 0.0025
        // which means there won't be a gas griefing fee
        hevm.warp(block.timestamp + 10**6 seconds);

        hevm.startPrank(LENDER_2);

        daiToken.mint(address(LENDER_2), 10 ether);
        daiToken.approve(address(liquidityProviders), 10 ether);
        liquidityProviders.supplyErc20(address(daiToken), 10 ether);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 9_974_000_000 + 1, // maximal improvment that still triggers term fee
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 1 ether,
            duration: 365 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);

        hevm.stopPrank();

        // Below are calculations concerning how much Lender 1 has after fees
        uint256 principal = 1 ether;
        uint256 interest = 10_000_000_000 * 10**6; // interest per second * seconds
        uint256 amtDrawn = 1 ether;
        uint256 originationFeeBps = 25;
        uint256 MAX_BPS = 10_000;
        uint256 feesFromLender2 = ((amtDrawn * originationFeeBps) / MAX_BPS);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            principal + interest + feesFromLender2
        );

        // Expect term griefing fee to have gone to protocol
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(OWNER, address(cDAIToken))
            ),
            1 ether * 0.0025
        );
    }

    function setupOwnerETHBalance() public {
        // Also Note: assuming DAI has decimals 18 throughout
        // even though the real version has decimals 6
        hevm.startPrank(LENDER_1);
        hevm.deal(LENDER_1, 1 ether);
        liquidityProviders.supplyEth{ value: 1 ether }();

        // Lender 1 has 1 DAI
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cEtherToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cEtherToken))
            ),
            1 ether
        );

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 10_000_000_000,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(ETH_ADDRESS),
            amount: 1 ether,
            duration: 365 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.stopPrank();

        // Borrower executes loan
        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        // Lender 1 has 1 fewer DAI, i.e., 0
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            0
        );

        // Protocol owner has 0
        // Would have more later if there were a term fee
        // But will still have 0 if there isn't
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(address(this), address(cDAIToken))
            ),
            0
        );

        // Warp ahead 10**6 seconds
        // 10**10 interest per second * 10**6 seconds = 10**16 interest
        // this is 0.01 of 10**18, which is over the gas griefing amount of 0.0025
        // which means there won't be a gas griefing fee
        hevm.warp(block.timestamp + 10**6 seconds);

        hevm.startPrank(LENDER_2);
        hevm.deal(address(LENDER_2), 10 ether);
        liquidityProviders.supplyEth{ value: 10 ether }();

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 9_974_000_000 + 1, // maximal improvment that still triggers term fee
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(ETH_ADDRESS),
            amount: 1 ether,
            duration: 365 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);

        hevm.stopPrank();

        // Below are calculations concerning how much Lender 1 has after fees
        uint256 principal = 1 ether;
        uint256 interest = 10_000_000_000 * 10**6; // interest per second * seconds
        uint256 amtDrawn = 1 ether;
        uint256 originationFeeBps = 25;
        uint256 MAX_BPS = 10_000;
        uint256 feesFromLender2 = ((amtDrawn * originationFeeBps) / MAX_BPS);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cEtherToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cEtherToken))
            ),
            principal + interest + feesFromLender2
        );

        // Expect term griefing fee to have gone to protocol
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cEtherToken),
                liquidityProviders.getCAssetBalance(OWNER, address(cEtherToken))
            ),
            1 ether * 0.0025
        );
    }

    // LENDER_1 makes an offer on mockNft #1, owned by address(this)
    // address(this) executes loan
    // LENDER_2 makes a better offer with a greater amount offered
    // LENDER_2 initiates refinance
    // Useful for testing drawLoanAmount functionality
    // which requires a lender-initiated refinance for a greater amount
    function setupRefinance() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444444,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 8 ether);
        daiToken.approve(address(liquidityProviders), 8 ether);

        liquidityProviders.supplyErc20(address(daiToken), 8 ether);

        hevm.warp(block.timestamp + 12 hours);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444444,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 7 ether,
            duration: 3 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);

        hevm.stopPrank();
    }

    function testGetOffer_returns_empty_offer() public {
        Offer memory offer = offersContract.getOffer(
            address(0x0000000000000000000000000000000000000001),
            2,
            "",
            false
        );

        assertEq(offer.creator, ZERO_ADDRESS);
        assertEq(offer.nftContractAddress, ZERO_ADDRESS);
        assertEq(offer.interestRatePerSecond, 0);
        assertTrue(!offer.fixedTerms);
        assertTrue(!offer.floorTerm);
        assertEq(offer.nftId, 0);
        assertEq(offer.asset, ZERO_ADDRESS);
        assertEq(offer.amount, 0);
        assertEq(offer.duration, 0);
        assertEq(offer.expiration, 0);
    }

    // createOffer Tests

    function testCannotCreateOffer_asset_not_whitelisted() public {
        Offer memory offer = Offer({
            creator: address(0x0000000000000000000000000000000000000001),
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 4,
            asset: address(0x0000000000000000000000000000000000000005),
            amount: 6,
            duration: 1 days,
            expiration: 8,
            floorTermLimit: 1
        });

        hevm.expectRevert("00040");

        offersContract.createOffer(offer);
    }

    function testCannotCreateOffer_offer_does_not_match_sender() public {
        Offer memory offer = Offer({
            creator: address(0x0000000000000000000000000000000000000001),
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.expectRevert("00024");

        offersContract.createOffer(offer);
    }

    function testCannotCreateOffer_not_enough_balance() public {
        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.expectRevert("00034");

        offersContract.createOffer(offer);
    }

    function testCreateOffer_works() public {
        daiToken.mint(address(this), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        Offer memory actual = offersContract.getOffer(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        assertEq(actual.creator, address(this));
        assertEq(actual.nftContractAddress, address(0x0000000000000000000000000000000000000002));
        assertEq(actual.interestRatePerSecond, 3);
        assertTrue(actual.fixedTerms);
        assertTrue(actual.floorTerm);
        assertTrue(actual.lenderOffer);
        assertEq(actual.nftId, 4);
        assertEq(actual.asset, address(daiToken));
        assertEq(actual.amount, 6);
        assertEq(actual.duration, 86400);
        assertEq(actual.expiration, uint32(block.timestamp + 1));
    }

    function testCreateOffer_works_event() public {
        daiToken.mint(address(this), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.expectEmit(true, false, false, true);

        emit NewOffer(
            address(this),
            address(0x0000000000000000000000000000000000000002),
            4,
            offer,
            offerHash
        );

        offersContract.createOffer(offer);
    }

    // removeOffer Tests

    function testCannotRemoveOffer_other_user() public {
        daiToken.mint(address(this), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.prank(address(0x0000000000000000000000000000000000000001));

        hevm.expectRevert("00024");

        offersContract.removeOffer(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testRemoveOffer_works_as_lendingContract() public {
        daiToken.mint(address(this), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.prank(address(lendingAuction));

        offersContract.removeOffer(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testRemoveOffer_works() public {
        daiToken.mint(address(this), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        offersContract.removeOffer(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        Offer memory actual = offersContract.getOffer(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        assertEq(actual.creator, ZERO_ADDRESS);
        assertEq(actual.nftContractAddress, ZERO_ADDRESS);
        assertEq(actual.interestRatePerSecond, 0);
        assertTrue(!actual.fixedTerms);
        assertTrue(!actual.floorTerm);
        assertEq(actual.nftId, 0);
        assertEq(actual.asset, ZERO_ADDRESS);
        assertEq(actual.amount, 0);
        assertEq(actual.duration, 0);
        assertEq(actual.expiration, 0);
    }

    function testRemoveOffer_event() public {
        daiToken.mint(address(this), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.expectEmit(true, false, false, true);

        emit OfferRemoved(
            address(this),
            address(0x0000000000000000000000000000000000000002),
            4,
            offer,
            offerHash
        );

        offersContract.removeOffer(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    // executeLoanByBorrower Tests

    function testCannotExecuteLoanByBorrower_asset_not_in_allow_list() public {
        daiToken.mint(address(this), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.prank(OWNER);
        liquidityProviders.setCAssetAddress(
            address(daiToken),
            address(0x0000000000000000000000000000000000000000)
        );

        hevm.expectRevert("00040");

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testCannotExecuteLoanByBorrower_no_offer_present() public {
        daiToken.mint(address(this), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: 8,
            floorTermLimit: 1
        });

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.expectRevert("00022");

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testCannotExecuteLoanByBorrower_offer_expired() public {
        daiToken.mint(address(this), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 30 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.warp(block.timestamp + 1 days);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.expectRevert("00010");

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testCannotExecuteLoanByBorrower_not_owning_nft() public {
        daiToken.mint(address(this), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        mockNft.transferFrom(address(this), address(0x0000000000000000000000000000000000000001), 1);

        hevm.expectRevert("00018");

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testCannotExecuteLoanByBorrower_not_enough_tokens() public {
        hevm.startPrank(LENDER_2);
        daiToken.mint(LENDER_2, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);
        hevm.stopPrank();

        hevm.startPrank(LENDER_1);
        daiToken.mint(LENDER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer1 = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer1);

        bytes32 offerHash1 = offersContract.getOfferHash(offer1);

        Offer memory offer2 = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 2,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        hevm.stopPrank();

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        // funds for first loan are available
        lendingAuction.executeLoanByBorrower(
            offer1.nftContractAddress,
            offer1.nftId,
            offerHash1,
            offer1.floorTerm
        );

        hevm.expectRevert("00034");

        lendingAuction.executeLoanByBorrower(
            offer2.nftContractAddress,
            offer2.nftId,
            offerHash2,
            offer2.floorTerm
        );
    }

    function testCannotExecuteLoanByBorrower_underlying_transfer_fails() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        daiToken.setTransferFail(true);

        hevm.expectRevert("SafeERC20: ERC20 operation did not succeed");

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testCannotExecuteLoanByBorrower_eth_payment_fails() public {
        hevm.startPrank(LENDER_1);

        liquidityProviders.supplyEth{ value: 6 }();

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: ETH_ADDRESS,
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        acceptEth = false;

        hevm.expectRevert("Address: unable to send value, recipient may have reverted");

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testCannotExecuteLoanByBorrower_borrower_offer() public {
        hevm.startPrank(LENDER_1);

        liquidityProviders.supplyEth{ value: 6 }();

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: ETH_ADDRESS,
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        mockNft.transferFrom(address(this), LENDER_1, 1);

        hevm.startPrank(LENDER_1);
        mockNft.approve(address(lendingAuction), 1);

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.expectRevert("00012");

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testExecuteLoanByBorrower_works_floor_term() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        assertEq(daiToken.balanceOf(address(this)), 6);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 0);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, LENDER_1);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 3);
        assertTrue(loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 6);
        assertEq(loanAuction.loanEndTimestamp, block.timestamp + 1 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6);

        // ensure that the offer is still there since its a floor offer

        Offer memory onChainOffer = offersContract.getOffer(address(mockNft), 1, offerHash, true);

        assertEq(onChainOffer.creator, LENDER_1);
        assertEq(onChainOffer.nftContractAddress, address(mockNft));
        assertEq(onChainOffer.interestRatePerSecond, 3);
        assertTrue(onChainOffer.fixedTerms);
        assertTrue(onChainOffer.floorTerm);
        assertTrue(onChainOffer.lenderOffer);
        assertEq(onChainOffer.nftId, 1);
        assertEq(onChainOffer.asset, address(daiToken));
        assertEq(onChainOffer.amount, 6);
        assertEq(onChainOffer.duration, 1 days);
        assertEq(onChainOffer.expiration, uint32(block.timestamp + 1));
    }

    function testExecuteLoanByBorrower_works_not_floor_term() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        assertEq(daiToken.balanceOf(address(this)), 6);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 0);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, LENDER_1);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 3);
        assertTrue(loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 6);
        assertEq(loanAuction.loanEndTimestamp, block.timestamp + 1 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6);

        // ensure that the offer is gone
        Offer memory onChainOffer = offersContract.getOffer(address(mockNft), 1, offerHash, false);

        assertEq(onChainOffer.creator, ZERO_ADDRESS);
        assertEq(onChainOffer.nftContractAddress, ZERO_ADDRESS);
        assertEq(onChainOffer.interestRatePerSecond, 0);
        assertTrue(!onChainOffer.fixedTerms);
        assertTrue(!onChainOffer.floorTerm);
        assertTrue(!onChainOffer.lenderOffer);
        assertEq(onChainOffer.nftId, 0);
        assertEq(onChainOffer.asset, ZERO_ADDRESS);
        assertEq(onChainOffer.amount, 0);
        assertEq(onChainOffer.duration, 0);
        assertEq(onChainOffer.expiration, 0);
    }

    function testExecuteLoanByBorrower_works_in_eth() public {
        hevm.startPrank(LENDER_1);

        liquidityProviders.supplyEth{ value: 6 }();

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: ETH_ADDRESS,
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        uint256 borrowerEthBalanceBefore = address(this).balance;
        uint256 lenderEthBalanceBefore = address(LENDER_1).balance;

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        assertEq(address(this).balance, borrowerEthBalanceBefore + 6);
        assertEq(cEtherToken.balanceOf(address(this)), 0);

        assertEq(address(LENDER_1).balance, lenderEthBalanceBefore);
        assertEq(cEtherToken.balanceOf(address(LENDER_1)), 0);

        assertEq(address(lendingAuction).balance, 0);
        assertEq(cEtherToken.balanceOf(address(lendingAuction)), 0);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));
    }

    function testExecuteLoanByBorrower_event() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectEmit(true, false, false, false);

        emit LoanExecuted(address(mockNft), 1, loanAuction);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    // executeLoanByBorrowerSignature Tests

    function testCannotExecuteLoanByBorrowerSignature_asset_not_in_allow_list() public {
        hevm.startPrank(SIGNER_1);

        daiToken.mint(SIGNER_1, 12);
        daiToken.approve(address(liquidityProviders), 12);

        liquidityProviders.supplyErc20(address(daiToken), 12);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.prank(OWNER);
        liquidityProviders.setCAssetAddress(
            address(daiToken),
            address(0x0000000000000000000000000000000000000000)
        );

        hevm.expectRevert("00040");

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 1);
    }

    function testCannotExecuteLoanByBorrowerSignature_signature_blocked() public {
        hevm.startPrank(SIGNER_1);

        daiToken.mint(SIGNER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: 8,
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        offersContract.withdrawOfferSignature(offer, signature);

        hevm.stopPrank();

        hevm.expectRevert("00032");

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 4);
    }

    function testCannotWithdrawOfferSignature_others_signature() public {
        hevm.startPrank(SIGNER_1);

        daiToken.mint(SIGNER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: 8,
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.stopPrank();

        hevm.prank(SIGNER_2);

        hevm.expectRevert("00033");

        offersContract.withdrawOfferSignature(offer, signature);
    }

    function testCannotExecuteLoanByBorrowerSignature_wrong_signer() public {
        hevm.startPrank(SIGNER_1);

        daiToken.mint(SIGNER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.stopPrank();

        hevm.expectRevert("00024");

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 4);
    }

    function testCannotExecuteLoanByBorrowerSignature_borrower_offer() public {
        hevm.startPrank(SIGNER_1);

        daiToken.mint(SIGNER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: false,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.stopPrank();

        hevm.expectRevert("00012");

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 4);
    }

    function testCannotExecuteLoanByBorrowerSignature_offer_expired() public {
        hevm.startPrank(SIGNER_1);

        daiToken.mint(SIGNER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: 8,
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.stopPrank();

        hevm.expectRevert("00010");

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 4);
    }

    function testCannotExecuteLoanByBorrowerSignature_offer_duration() public {
        hevm.startPrank(SIGNER_1);

        daiToken.mint(SIGNER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days - 1,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.stopPrank();

        hevm.expectRevert("00011");

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 4);
    }

    function testCannotExecuteLoanByBorrowerSignature_not_owning_nft() public {
        hevm.startPrank(SIGNER_1);

        daiToken.mint(SIGNER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        mockNft.transferFrom(address(this), address(0x0000000000000000000000000000000000000001), 1);
        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.expectRevert("00018");

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 1);
    }

    function testCannotExecuteLoanByBorrowerSignature_not_enough_tokens() public {
        hevm.startPrank(SIGNER_1);

        daiToken.mint(SIGNER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 7,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.expectRevert("ERC20: burn amount exceeds balance");

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 1);
    }

    function testCannotExecuteLoanByBorrowerSignature_underlying_transfer_fails() public {
        hevm.startPrank(SIGNER_1);

        daiToken.mint(SIGNER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        daiToken.setTransferFail(true);

        hevm.expectRevert("SafeERC20: ERC20 operation did not succeed");

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 1);
    }

    function testCannotExecuteLoanByBorrowerSignature_eth_payment_fails() public {
        AddressUpgradeable.sendValue(payable(SIGNER_1), 6);

        hevm.startPrank(SIGNER_1);

        liquidityProviders.supplyEth{ value: 6 }();

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: ETH_ADDRESS,
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        acceptEth = false;

        hevm.expectRevert("Address: unable to send value, recipient may have reverted");

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 1);
    }

    function testExecuteLoanByBorrowerSignature_works_floor_term() public {
        hevm.startPrank(SIGNER_1);

        daiToken.mint(SIGNER_1, 12);
        daiToken.approve(address(liquidityProviders), 12);

        liquidityProviders.supplyErc20(address(daiToken), 12);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 2
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 1);

        assertEq(daiToken.balanceOf(address(this)), 6);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 6 ether);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, SIGNER_1);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 3);
        assertTrue(loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 6);
        assertEq(loanAuction.loanEndTimestamp, block.timestamp + 1 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6);

        // ensure that the offer is still there since its a floor offer
        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 2);
    }

    function testExecuteLoanByBorrowerSignature_works_not_floor_term() public {
        hevm.startPrank(SIGNER_1);

        daiToken.mint(SIGNER_1, 12);
        daiToken.approve(address(liquidityProviders), 12);

        liquidityProviders.supplyErc20(address(daiToken), 12);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 1);

        assertEq(daiToken.balanceOf(address(this)), 6);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(SIGNER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(SIGNER_1)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 6 ether);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, SIGNER_1);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 3);
        assertTrue(loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 6);
        assertEq(loanAuction.loanEndTimestamp, block.timestamp + 1 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6);

        // ensure that the offer is gone
        hevm.expectRevert("00032");

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 2);
    }

    function testExecuteLoanByBorrowerSignature_works_in_eth() public {
        AddressUpgradeable.sendValue(payable(SIGNER_1), 6);
        hevm.startPrank(SIGNER_1);

        liquidityProviders.supplyEth{ value: 6 }();

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: ETH_ADDRESS,
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        uint256 borrowerEthBalanceBefore = address(this).balance;
        uint256 lenderEthBalanceBefore = address(SIGNER_1).balance;

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 1);

        assertEq(address(this).balance, borrowerEthBalanceBefore + 6);
        assertEq(cEtherToken.balanceOf(address(this)), 0);

        assertEq(address(SIGNER_1).balance, lenderEthBalanceBefore);
        assertEq(cEtherToken.balanceOf(address(SIGNER_1)), 0);

        assertEq(address(lendingAuction).balance, 0);
        assertEq(cEtherToken.balanceOf(address(lendingAuction)), 0);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));
    }

    function testExecuteLoanByBorrowerSignature_event() public {
        hevm.startPrank(SIGNER_1);

        daiToken.mint(SIGNER_1, 12);
        daiToken.approve(address(liquidityProviders), 12);

        liquidityProviders.supplyErc20(address(daiToken), 12);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectEmit(true, false, false, false);

        emit LoanExecuted(address(mockNft), 1, loanAuction);

        emit AmountDrawn(address(mockNft), 1, 6, loanAuction);

        emit OfferSignatureUsed(address(mockNft), 1, offer, signature);

        sigLendingAuction.executeLoanByBorrowerSignature(offer, signature, 1);
    }

    // executeLoanByLender Tests

    function testCannotExecuteLoanByLender_asset_not_in_allow_list() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        hevm.stopPrank();

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.prank(OWNER);
        liquidityProviders.setCAssetAddress(
            address(daiToken),
            address(0x0000000000000000000000000000000000000000)
        );

        hevm.expectRevert("00040");

        hevm.startPrank(LENDER_1);

        lendingAuction.executeLoanByLender(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testCannotExecuteLoanByLender_no_offer_present() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);
        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: false,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: 8,
            floorTermLimit: 1
        });

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.expectRevert("00004");

        lendingAuction.executeLoanByLender(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testCannotExecuteLoanByLender_offer_expired() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);
        liquidityProviders.supplyErc20(address(daiToken), 6);
        hevm.stopPrank();

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        mockNft.transferFrom(address(this), SIGNER_1, 1);

        hevm.startPrank(SIGNER_1);
        mockNft.approve(address(lendingAuction), 1);
        hevm.stopPrank();

        hevm.startPrank(SIGNER_1);

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.expectRevert("00010");

        hevm.stopPrank();

        hevm.warp(block.timestamp + 1 days);

        hevm.startPrank(LENDER_1);

        lendingAuction.executeLoanByLender(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testCannotExecuteLoanByLender_not_owning_nft() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);
        liquidityProviders.supplyErc20(address(daiToken), 6);
        hevm.stopPrank();

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        mockNft.transferFrom(address(this), address(0x0000000000000000000000000000000000000001), 1);

        hevm.expectRevert("00018");

        hevm.startPrank(LENDER_1);

        lendingAuction.executeLoanByLender(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testCannotExecuteLoanByLender_not_enough_tokens() public {
        hevm.startPrank(LENDER_2);
        daiToken.mint(LENDER_2, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);
        hevm.stopPrank();

        hevm.startPrank(LENDER_1);
        daiToken.mint(LENDER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        hevm.stopPrank();

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 7,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.startPrank(LENDER_1);

        hevm.expectRevert("00034");

        lendingAuction.executeLoanByLender(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testCannotExecuteLoanByLender_underlying_transfer_fails() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(LENDER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        hevm.stopPrank();

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        daiToken.setTransferFail(true);

        hevm.startPrank(LENDER_1);

        hevm.expectRevert("SafeERC20: ERC20 operation did not succeed");

        lendingAuction.executeLoanByLender(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testCannotExecuteLoanByLender_eth_payment_fails() public {
        hevm.startPrank(LENDER_1);

        liquidityProviders.supplyEth{ value: 6 }();

        hevm.stopPrank();

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: ETH_ADDRESS,
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        acceptEth = false;

        hevm.expectRevert("Address: unable to send value, recipient may have reverted");

        hevm.startPrank(LENDER_1);

        lendingAuction.executeLoanByLender(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testCannotExecuteLoanByLender_lender_offer() public {
        hevm.startPrank(LENDER_1);

        liquidityProviders.supplyEth{ value: 6 }();

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: ETH_ADDRESS,
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.expectRevert("00013");

        lendingAuction.executeLoanByLender(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testCannotExecuteLoanByLender_floor_term() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);
        hevm.stopPrank();

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.expectRevert("00014");
        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.startPrank(LENDER_1);

        hevm.expectRevert("00004");
        lendingAuction.executeLoanByLender(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    function testExecuteLoanByLender_works_not_floor_term() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        hevm.stopPrank();

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.startPrank(LENDER_1);

        lendingAuction.executeLoanByLender(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        assertEq(daiToken.balanceOf(address(this)), 6);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 0);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, LENDER_1);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 3);
        assertTrue(loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 6);
        assertEq(loanAuction.loanEndTimestamp, block.timestamp + 1 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6);

        // ensure that the offer is gone
        Offer memory onChainOffer = offersContract.getOffer(address(mockNft), 1, offerHash, false);

        assertEq(onChainOffer.creator, ZERO_ADDRESS);
        assertEq(onChainOffer.nftContractAddress, ZERO_ADDRESS);
        assertEq(onChainOffer.interestRatePerSecond, 0);
        assertTrue(!onChainOffer.fixedTerms);
        assertTrue(!onChainOffer.floorTerm);
        assertTrue(!onChainOffer.lenderOffer);
        assertEq(onChainOffer.nftId, 0);
        assertEq(onChainOffer.asset, ZERO_ADDRESS);
        assertEq(onChainOffer.amount, 0);
        assertEq(onChainOffer.duration, 0);
        assertEq(onChainOffer.expiration, 0);
    }

    function testExecuteLoanByLender_works_in_eth() public {
        hevm.startPrank(LENDER_1);

        liquidityProviders.supplyEth{ value: 6 }();

        hevm.stopPrank();

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: ETH_ADDRESS,
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        uint256 borrowerEthBalanceBefore = address(this).balance;
        uint256 lenderEthBalanceBefore = address(LENDER_1).balance;

        hevm.startPrank(LENDER_1);

        lendingAuction.executeLoanByLender(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        assertEq(address(this).balance, borrowerEthBalanceBefore + 6);
        assertEq(cEtherToken.balanceOf(address(this)), 0);

        assertEq(address(LENDER_1).balance, lenderEthBalanceBefore);
        assertEq(cEtherToken.balanceOf(address(LENDER_1)), 0);

        assertEq(address(lendingAuction).balance, 0);
        assertEq(cEtherToken.balanceOf(address(lendingAuction)), 0);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));
    }

    function testExecuteLoanByLender_event() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        hevm.stopPrank();

        Offer memory offer = Offer({
            creator: address(this),
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectEmit(true, false, false, false);

        emit LoanExecuted(address(mockNft), 1, loanAuction);

        emit AmountDrawn(address(mockNft), 1, 6, loanAuction);

        hevm.startPrank(LENDER_1);

        lendingAuction.executeLoanByLender(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );
    }

    // executeLoanByLenderSignature Tests

    function testCannotExecuteLoanByLenderSignature_asset_not_in_allow_list() public {
        hevm.startPrank(LENDER_1);

        daiToken.mint(LENDER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        mockNft.transferFrom(address(this), SIGNER_1, 1);

        hevm.startPrank(SIGNER_1);
        mockNft.approve(address(lendingAuction), 1);
        hevm.stopPrank();

        hevm.prank(OWNER);
        liquidityProviders.setCAssetAddress(
            address(daiToken),
            address(0x0000000000000000000000000000000000000000)
        );

        hevm.startPrank(LENDER_1);

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.expectRevert("00040");

        sigLendingAuction.executeLoanByLenderSignature(offer, signature);
    }

    function testCannotExecuteLoanByLenderSignature_signature_blocked() public {
        hevm.startPrank(LENDER_1);

        daiToken.mint(LENDER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 7,
            expiration: 8,
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.stopPrank();
        hevm.startPrank(SIGNER_1);
        offersContract.withdrawOfferSignature(offer, signature);

        hevm.expectRevert("00032");
        hevm.stopPrank();
        hevm.startPrank(LENDER_1);
        sigLendingAuction.executeLoanByLenderSignature(offer, signature);
    }

    function testCannotExecuteLoanByLenderSignature_wrong_signer() public {
        hevm.startPrank(LENDER_1);

        daiToken.mint(LENDER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 7,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.expectRevert("00024");

        sigLendingAuction.executeLoanByLenderSignature(offer, signature);
    }

    function testCannotExecuteLoanByLenderSignature_lender_offer() public {
        hevm.startPrank(LENDER_1);

        daiToken.mint(LENDER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: true,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.stopPrank();

        hevm.expectRevert("00013");

        sigLendingAuction.executeLoanByLenderSignature(offer, signature);
    }

    function testCannotExecuteLoanByLenderSignature_offer_expired() public {
        hevm.startPrank(LENDER_1);

        daiToken.mint(LENDER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: 8,
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.stopPrank();

        hevm.expectRevert("00010");

        sigLendingAuction.executeLoanByLenderSignature(offer, signature);
    }

    function testCannotExecuteLoanByLenderSignature_offer_duration() public {
        hevm.startPrank(LENDER_1);

        daiToken.mint(LENDER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(0x0000000000000000000000000000000000000002),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 4,
            asset: address(daiToken),
            amount: 6,
            duration: 7,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.stopPrank();

        hevm.expectRevert("00011");

        sigLendingAuction.executeLoanByLenderSignature(offer, signature);
    }

    function testCannotExecuteLoanByLenderSignature_not_owning_nft() public {
        hevm.startPrank(LENDER_1);

        daiToken.mint(LENDER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.expectRevert("00018");

        sigLendingAuction.executeLoanByLenderSignature(offer, signature);
    }

    function testCannotExecuteLoanByLenderSignature_not_enough_tokens() public {
        hevm.startPrank(LENDER_1);

        daiToken.mint(LENDER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 7,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        mockNft.transferFrom(address(this), SIGNER_1, 1);

        hevm.startPrank(SIGNER_1);
        mockNft.approve(address(lendingAuction), 1);
        hevm.stopPrank();

        hevm.startPrank(LENDER_1);

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        hevm.expectRevert("ERC20: burn amount exceeds balance");

        sigLendingAuction.executeLoanByLenderSignature(offer, signature);
    }

    function testCannotExecuteLoanByLenderSignature_underlying_transfer_fails() public {
        hevm.startPrank(LENDER_1);

        daiToken.mint(LENDER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        mockNft.transferFrom(address(this), SIGNER_1, 1);

        hevm.startPrank(SIGNER_1);
        mockNft.approve(address(lendingAuction), 1);
        hevm.stopPrank();

        hevm.startPrank(LENDER_1);

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        daiToken.setTransferFail(true);

        hevm.expectRevert("SafeERC20: ERC20 operation did not succeed");

        sigLendingAuction.executeLoanByLenderSignature(offer, signature);
    }

    function testExecuteLoanByLenderSignature_works_not_floor_term() public {
        hevm.startPrank(LENDER_1);

        daiToken.mint(LENDER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        mockNft.transferFrom(address(this), SIGNER_1, 1);

        hevm.startPrank(SIGNER_1);
        mockNft.approve(address(lendingAuction), 1);
        hevm.stopPrank();

        hevm.startPrank(LENDER_1);

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        sigLendingAuction.executeLoanByLenderSignature(offer, signature);

        assertEq(daiToken.balanceOf(LENDER_1), 0);
        assertEq(cDAIToken.balanceOf(LENDER_1), 0);

        assertEq(daiToken.balanceOf(address(SIGNER_1)), 6);
        assertEq(cDAIToken.balanceOf(address(SIGNER_1)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 0);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), SIGNER_1);

        assertEq(liquidityProviders.getCAssetBalance(SIGNER_1, address(cDAIToken)), 0);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, SIGNER_1);
        assertEq(loanAuction.lender, LENDER_1);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 3);
        assertTrue(loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 6);
        assertEq(loanAuction.loanEndTimestamp, block.timestamp + 1 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6);

        // ensure that the offer is gone
        hevm.expectRevert("00032");

        sigLendingAuction.executeLoanByLenderSignature(offer, signature);
    }

    function testExecuteLoanByLenderSignature_works_in_eth() public {
        AddressUpgradeable.sendValue(payable(LENDER_1), 6);
        hevm.startPrank(LENDER_1);

        liquidityProviders.supplyEth{ value: 6 }();

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: ETH_ADDRESS,
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        mockNft.transferFrom(address(this), SIGNER_1, 1);

        hevm.startPrank(SIGNER_1);
        mockNft.approve(address(lendingAuction), 1);
        hevm.stopPrank();

        hevm.startPrank(LENDER_1);

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        uint256 borrowerEthBalanceBefore = address(SIGNER_1).balance;
        uint256 lenderEthBalanceBefore = address(LENDER_1).balance;

        sigLendingAuction.executeLoanByLenderSignature(offer, signature);

        assertEq(address(SIGNER_1).balance, borrowerEthBalanceBefore + 6);
        assertEq(cEtherToken.balanceOf(address(SIGNER_1)), 0);

        assertEq(address(LENDER_1).balance, lenderEthBalanceBefore);
        assertEq(cEtherToken.balanceOf(address(LENDER_1)), 0);

        assertEq(address(lendingAuction).balance, 0);
        assertEq(cEtherToken.balanceOf(address(lendingAuction)), 0);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(SIGNER_1));
    }

    function testExecuteLoanByLenderSignature_event() public {
        hevm.startPrank(LENDER_1);

        daiToken.mint(LENDER_1, 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        mockNft.transferFrom(address(this), SIGNER_1, 1);

        hevm.startPrank(SIGNER_1);
        mockNft.approve(address(lendingAuction), 1);
        hevm.stopPrank();

        hevm.startPrank(LENDER_1);

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectEmit(true, false, false, false);

        emit LoanExecuted(address(mockNft), 1, loanAuction);

        emit AmountDrawn(address(mockNft), 1, 6, loanAuction);

        emit OfferSignatureUsed(address(mockNft), 1, offer, signature);

        sigLendingAuction.executeLoanByLenderSignature(offer, signature);
    }

    // refinanceByBorrower Tests

    function testCannotRefinanceByBorrower_fixed_terms() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        hevm.stopPrank();

        hevm.expectRevert("00015");

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            1,
            true,
            offerHash2,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrower_borrower_offer() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: address(this),
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });
        hevm.stopPrank();
        offersContract.createOffer(offer2);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        hevm.expectRevert("00012");

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            1,
            false,
            offerHash2,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrower_not_floor_term_mismatch_nftid() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 2,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        hevm.stopPrank();

        hevm.expectRevert("00022");

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            3,
            false,
            offerHash2,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrower_borrower_not_nft_owner() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 2,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        hevm.expectRevert("00019");

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            2,
            false,
            offerHash2,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrower_no_open_loan() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 2,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        hevm.stopPrank();

        daiToken.approve(address(liquidityProviders), 6);

        lendingAuction.repayLoan(address(mockNft), 1);

        hevm.expectRevert("00019");

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            2,
            true,
            offerHash2,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrower_nft_owner() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        hevm.stopPrank();
        hevm.startPrank(LENDER_1);

        daiToken.approve(address(liquidityProviders), 6);

        hevm.expectRevert("00021");

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            1,
            true,
            offerHash2,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrower_nft_contract_address() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(0x02),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        hevm.expectRevert("00022");

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            1,
            false,
            offerHash2,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrower_nft_id() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 2,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        // hevm.stopPrank();
        // hevm.startPrank(LENDER_1);

        // daiToken.approve(address(liquidityProviders), 6);

        hevm.expectRevert("00022");

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            1,
            false,
            offerHash2,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrower_wrong_asset() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        AddressUpgradeable.sendValue(payable(LENDER_2), 6);

        hevm.startPrank(LENDER_2);

        liquidityProviders.supplyEth{ value: 6 }();

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: ETH_ADDRESS,
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        hevm.stopPrank();
        hevm.startPrank(LENDER_1);

        daiToken.approve(address(liquidityProviders), 6);

        hevm.expectRevert("00019");

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            1,
            false,
            offerHash2,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrower_offer_expired() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        hevm.stopPrank();

        hevm.warp(block.timestamp + 2);

        hevm.expectRevert("00010");

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            1,
            true,
            offerHash2,
            uint32(block.timestamp - 2)
        );
    }

    function testRefinanceByBorrower_works() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 3 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        hevm.stopPrank();

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            1,
            true,
            offerHash2,
            uint32(block.timestamp)
        );

        assertEq(daiToken.balanceOf(address(this)), 6);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_2)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_2)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 6 ether);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);
        assertEq(liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)), 6 ether);
        assertEq(liquidityProviders.getCAssetBalance(LENDER_2, address(cDAIToken)), 0);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, LENDER_2);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 2);
        assertTrue(!loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 6);
        assertEq(loanAuction.loanEndTimestamp, block.timestamp + 3 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6);
    }

    function testRefinanceByBorrower_works_into_fix_term() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 3 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        hevm.stopPrank();

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            1,
            true,
            offerHash2,
            uint32(block.timestamp)
        );

        assertEq(daiToken.balanceOf(address(this)), 6);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_2)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_2)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 6 ether);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);
        assertEq(liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)), 6 ether);
        assertEq(liquidityProviders.getCAssetBalance(LENDER_2, address(cDAIToken)), 0);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, LENDER_2);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 2);
        assertTrue(loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 6);
        assertEq(loanAuction.loanEndTimestamp, block.timestamp + 3 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6);
    }

    function testRefinanceByBorrower_events() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 3 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        hevm.stopPrank();

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectEmit(true, false, false, false);

        emit Refinance(address(mockNft), 1, loanAuction);

        emit AmountDrawn(offer.nftContractAddress, 1, 0, loanAuction);

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            1,
            true,
            offerHash2,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrower_does_not_cover_interest() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 3 days,
            expiration: uint32(block.timestamp + 200),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        hevm.stopPrank();

        hevm.warp(block.timestamp + 100);

        hevm.expectRevert("00005");

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            1,
            true,
            offerHash2,
            uint32(block.timestamp - 100)
        );
    }

    function testRefinanceByBorrower_covers_interest() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444444, // 1% interest on 6 eth for 86400 seconds
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 10 ether);
        daiToken.approve(address(liquidityProviders), 10 ether);

        liquidityProviders.supplyErc20(address(daiToken), 10 ether);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444442,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 7 ether,
            duration: 3 days,
            expiration: uint32(block.timestamp + 13 hours),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer2);

        bytes32 offerHash2 = offersContract.getOfferHash(offer2);

        hevm.stopPrank();

        hevm.warp(block.timestamp + 12 hours);

        lendingAuction.refinanceByBorrower(
            address(mockNft),
            1,
            true,
            offerHash2,
            uint32(block.timestamp - 12 hours)
        );

        assertEq(daiToken.balanceOf(address(this)), 6 ether);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_2)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_2)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 10 ether * 10**18);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);
        assertEq(
            liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)),
            6044999999999980800 ether
        );
        assertEq(
            liquidityProviders.getCAssetBalance(LENDER_2, address(cDAIToken)),
            3955000000000019200 ether
        );

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, LENDER_2);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 601701388888);
        assertTrue(!loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 7 ether);
        assertEq(loanAuction.loanEndTimestamp, loanAuction.loanBeginTimestamp + 3 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0); // 0 fee set so 0 balance expected
    }

    // refinanceByBorrowerSignature Tests

    function testCannotRefinanceByBorrowerSignature_fixed_terms() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        hevm.stopPrank();

        hevm.expectRevert("00015");

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrowerSignature_withdrawn_signature() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        offersContract.withdrawOfferSignature(offer2, signature);

        hevm.stopPrank();

        hevm.expectRevert("00032");

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrowerSignature_min_duration() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days - 1,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        hevm.stopPrank();

        hevm.expectRevert("00011");

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrowerSignature_borrower_offer() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });
        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        hevm.expectRevert("00012");

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrowerSignature_not_floor_term_mismatch_nftid() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 2,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        hevm.expectRevert("00022");

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrowerSignature_borrower_not_nft_owner() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 2,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        hevm.startPrank(BORROWER_1);

        hevm.expectRevert("00021");

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrowerSignature_no_open_loan() public {
        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 2,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        mockNft.transferFrom(address(this), address(0x1), 1);
        hevm.expectRevert("00019");

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrowerSignature_nft_contract_address() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(0x02),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        hevm.expectRevert("00019");

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrowerSignature_nft_id() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 2,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        hevm.expectRevert("00022");

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrowerSignature_wrong_asset() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        AddressUpgradeable.sendValue(payable(SIGNER_1), 6);

        hevm.startPrank(SIGNER_1);

        liquidityProviders.supplyEth{ value: 6 }();

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: ETH_ADDRESS,
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        hevm.expectRevert("00019");

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrowerSignature_offer_expired() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        hevm.warp(block.timestamp + 2);
        hevm.expectRevert("00010");

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp - 2)
        );
    }

    function testRefinanceByBorrowerSignature_works_floor_term() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 3 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp)
        );

        assertEq(daiToken.balanceOf(address(this)), 6);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(SIGNER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(SIGNER_1)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 6 ether);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);
        assertEq(liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)), 6 ether);
        assertEq(liquidityProviders.getCAssetBalance(SIGNER_1, address(cDAIToken)), 0);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, SIGNER_1);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 2);
        assertTrue(!loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 6);
        assertEq(loanAuction.loanEndTimestamp, block.timestamp + 3 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6);

        // ensure the signature is not invalidated
        assertTrue(!offersContract.getOfferSignatureStatus(signature));
    }

    function testRefinanceByBorrowerSignature_works_not_floor_term() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 3 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp)
        );

        assertEq(daiToken.balanceOf(address(this)), 6);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(SIGNER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(SIGNER_1)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 6 ether);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);
        assertEq(liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)), 6 ether);
        assertEq(liquidityProviders.getCAssetBalance(SIGNER_1, address(cDAIToken)), 0);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, SIGNER_1);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 2);
        assertTrue(!loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 6);
        assertEq(loanAuction.loanEndTimestamp, block.timestamp + 3 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6);

        assertTrue(offersContract.getOfferSignatureStatus(signature));
    }

    function testRefinanceByBorrowerSignature_works_into_fix_term() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 3 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp)
        );

        assertEq(daiToken.balanceOf(address(this)), 6);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(SIGNER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(SIGNER_1)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 6 ether);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);
        assertEq(liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)), 6 ether);
        assertEq(liquidityProviders.getCAssetBalance(SIGNER_1, address(cDAIToken)), 0);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, SIGNER_1);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 2);
        assertTrue(loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 6);
        assertEq(loanAuction.loanEndTimestamp, block.timestamp + 3 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6);
    }

    function testRefinanceByBorrowerSignature_events() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 3 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectEmit(true, true, true, true);

        emit OfferSignatureUsed(address(mockNft), 1, offer2, signature);

        emit Refinance(address(mockNft), 1, loanAuction);

        emit AmountDrawn(offer.nftContractAddress, 1, 0, loanAuction);

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrowerSignature_does_not_cover_interest() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 3 days,
            expiration: uint32(block.timestamp + 200),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        hevm.expectRevert("00005");

        hevm.warp(block.timestamp + 100);

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp - 100)
        );
    }

    function testRefinanceByBorrowerSignature_covers_interest() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444444, // 1% interest on 6 eth for 86400 seconds
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 10 ether);
        daiToken.approve(address(liquidityProviders), 10 ether);

        liquidityProviders.supplyErc20(address(daiToken), 10 ether);

        Offer memory offer2 = Offer({
            creator: SIGNER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444442,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 7 ether,
            duration: 3 days,
            expiration: uint32(block.timestamp + 13 hours),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        bytes memory signature = signOffer(SIGNER_PRIVATE_KEY_1, offer2);

        hevm.warp(block.timestamp + 12 hours);

        sigLendingAuction.refinanceByBorrowerSignature(
            offer2,
            signature,
            1,
            uint32(block.timestamp - 12 hours)
        );

        assertEq(daiToken.balanceOf(address(this)), 6 ether);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(SIGNER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(SIGNER_1)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 10 ether * 10**18);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);
        assertEq(
            liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)),
            6044999999999980800 ether
        );
        assertEq(
            liquidityProviders.getCAssetBalance(SIGNER_1, address(cDAIToken)),
            3955000000000019200 ether
        );

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, SIGNER_1);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 601701388888);
        assertTrue(!loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 7 ether);
        assertEq(loanAuction.loanEndTimestamp, loanAuction.loanBeginTimestamp + 3 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0); // 0 fee set so 0 balance expected
    }

    // refinanceByLender Tests

    function testCannotRefinanceByLender_fixed_terms() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectRevert("00015");

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);
    }

    function testCannotRefinanceByLender_no_improvements_in_terms() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectRevert("00025");

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);
    }

    function testCannotRefinanceByLender_borrower_offer() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.stopPrank();

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: false,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectRevert("00012");

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);
    }

    function testCannotRefinanceByLender_mismatch_nftid() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 2,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        hevm.startPrank(LENDER_2);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectRevert("00007");

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);
    }

    function testCannotRefinanceByLender_borrower_not_nft_owner() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 2,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 2,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectRevert("00007");

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);
    }

    function testCannotRefinanceByLender_no_open_loan() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 2,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        hevm.stopPrank();

        daiToken.approve(address(liquidityProviders), 6);

        lendingAuction.repayLoan(address(mockNft), 1);

        hevm.startPrank(LENDER_2);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectRevert("00007");

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);
    }

    function testCannotRefinanceByLender_nft_contract_address() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(0x02),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectRevert("00007");

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);
    }

    function testCannotRefinanceByLender_nft_id() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 2,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectRevert("00007");

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);
    }

    function testCannotRefinanceByLender_wrong_asset() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        AddressUpgradeable.sendValue(payable(LENDER_2), 6);

        hevm.startPrank(LENDER_2);

        liquidityProviders.supplyEth{ value: 6 }();

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: ETH_ADDRESS,
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectRevert("00019");

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);
    }

    function testCannotRefinanceByLender_offer_expired() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.warp(block.timestamp + 2);

        hevm.expectRevert("00010");

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);
    }

    function testCannotRefinanceByLender_if_sanctioned() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(SANCTIONED_ADDRESS);
        daiToken.mint(address(SANCTIONED_ADDRESS), 6);
        daiToken.approve(address(liquidityProviders), 6);

        // Cannot supplyErc20 as a sanctioned address.
        // This would actually revert here.
        // We can actually run this test without supplying any liquidity
        // because currently the sanctions check occurs before
        // checking to make sure the lender has sufficient balance
        // for the refinance offer.

        // lendingAuction.supplyErc20(address(daiToken), 6);

        Offer memory offer2 = Offer({
            creator: SANCTIONED_ADDRESS,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectRevert("00017");

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);
    }

    function testRefinanceByBorrower_works_different_lender() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 6844444400000,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 8 ether);
        daiToken.approve(address(liquidityProviders), 8 ether);

        liquidityProviders.supplyErc20(address(daiToken), 8 ether);

        hevm.warp(block.timestamp + 12 hours);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 6844444400000,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 7 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);

        assertEq(daiToken.balanceOf(address(this)), 6 ether);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_2)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_2)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 8 ether * 10**18);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);
        assertEq(
            liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)),
            6310679998080000000 ether
        );
        assertEq(
            liquidityProviders.getCAssetBalance(LENDER_2, address(cDAIToken)),
            1689320001920000000 ether
        );

        assertEq(liquidityProviders.getCAssetBalance(OWNER, address(cDAIToken)), 0 ether);

        loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, LENDER_2);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 6844444400000);
        assertTrue(!loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 7 ether);
        assertEq(loanAuction.loanEndTimestamp, block.timestamp + 1 days - 12 hours);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 295679998080000000);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6 ether);
    }

    function testCannotRefinanceByLender_into_fixed_term() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 7 ether);
        daiToken.approve(address(liquidityProviders), 7 ether);

        liquidityProviders.supplyErc20(address(daiToken), 7 ether);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: true,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 7 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectRevert("00016");

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);
    }

    function testRefinanceByLender_events() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 6845444400000,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 7 ether);
        daiToken.approve(address(liquidityProviders), 7 ether);

        liquidityProviders.supplyErc20(address(daiToken), 7 ether);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 6844444400000,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether + 0.015 ether,
            duration: 1 days + 3.7 minutes,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectEmit(true, true, false, false);

        emit Refinance(address(mockNft), 1, loanAuction);

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);
    }

    function testRefinanceByLender_covers_interest() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444444,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 10 ether);
        daiToken.approve(address(liquidityProviders), 10 ether);

        liquidityProviders.supplyErc20(address(daiToken), 10 ether);

        hevm.warp(block.timestamp + 6 hours + 10 minutes);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444440,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 7 ether,
            duration: 3 days,
            expiration: uint32(block.timestamp + 200),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);

        assertEq(daiToken.balanceOf(address(this)), 6 ether);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_2)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_2)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 10 ether * 10**18);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);
        assertEq(
            liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)),
            6030416666666656800 ether
        );
        assertEq(
            liquidityProviders.getCAssetBalance(LENDER_2, address(cDAIToken)),
            3969583333333343200 ether
        );

        assertEq(
            liquidityProviders.getCAssetBalance(OWNER, address(cDAIToken)),
            0 ether // premium at 0 so no balance expected
        );

        loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, LENDER_2);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 694444444440);
        assertTrue(!loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 7 ether);
        assertEq(loanAuction.loanEndTimestamp, loanAuction.loanBeginTimestamp + 3 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 15416666666656800);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6000000000000000000);
    }

    function testRefinanceByLender_same_lender() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444444, // 1% interest on 6 eth for 86400 seconds
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 10 ether);
        daiToken.approve(address(liquidityProviders), 10 ether);

        liquidityProviders.supplyErc20(address(daiToken), 10 ether);

        Offer memory offer2 = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444442,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 3 days,
            expiration: uint32(block.timestamp + 200),
            floorTermLimit: 1
        });

        hevm.warp(block.timestamp + 100);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);

        assertEq(daiToken.balanceOf(address(this)), 6 ether);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 10 ether * 10**18);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);
        assertEq(
            liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)),
            10000000000000000000 ether
        );

        assertEq(liquidityProviders.getCAssetBalance(OWNER, address(cDAIToken)), 0);

        loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, LENDER_1);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 694444444442);
        assertTrue(!loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 6 ether);
        assertEq(loanAuction.loanEndTimestamp, loanAuction.loanBeginTimestamp + 3 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 69444444444400);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6 ether);
    }

    function testRefinanceByLender_covers_interest_3_lenders() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444444,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 10 ether);
        daiToken.approve(address(liquidityProviders), 10 ether);

        liquidityProviders.supplyErc20(address(daiToken), 10 ether);

        hevm.warp(block.timestamp + 6 hours + 10 minutes);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444442,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 7 ether,
            duration: 3 days,
            expiration: uint32(block.timestamp + 200),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);

        hevm.stopPrank();

        hevm.startPrank(LENDER_3);
        daiToken.mint(address(LENDER_3), 10 ether);
        daiToken.approve(address(liquidityProviders), 10 ether);

        liquidityProviders.supplyErc20(address(daiToken), 10 ether);

        hevm.warp(block.timestamp + 6 hours + 10 minutes);

        Offer memory offer3 = Offer({
            creator: LENDER_3,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444440,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 8 ether,
            duration: 3 days,
            expiration: uint32(block.timestamp + 400),
            floorTermLimit: 1
        });

        loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        lendingAuction.refinanceByLender(offer3, loanAuction.lastUpdatedTimestamp);

        assertEq(daiToken.balanceOf(address(this)), 6 ether);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_1)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_1)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_2)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_2)), 0);

        assertEq(daiToken.balanceOf(address(LENDER_3)), 0);
        assertEq(cDAIToken.balanceOf(address(LENDER_3)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 20 ether * 10**18);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));
        assertEq(lendingAuction.ownerOf(address(mockNft), 1), address(this));

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);
        assertEq(
            liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)),
            6030416666666656800 ether
        );
        assertEq(
            liquidityProviders.getCAssetBalance(LENDER_2, address(cDAIToken)),
            10015416666666612400 ether
        );

        assertEq(
            liquidityProviders.getCAssetBalance(LENDER_3, address(cDAIToken)),
            3954166666666730800 ether
        );

        assertEq(
            liquidityProviders.getCAssetBalance(OWNER, address(cDAIToken)),
            0 ether // protocol premium is 0 so owner has no balance
        );

        loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, LENDER_3);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 694444444440);
        assertTrue(!loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 8 ether);
        assertEq(loanAuction.loanEndTimestamp, loanAuction.loanBeginTimestamp + 3 days);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 30833333333269200);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 6000000000000000000);
    }

    function testCannotSeizeAsset_asset_missing_in_allow_list() public {
        hevm.expectRevert("00040");
        lendingAuction.seizeAsset(address(0x1), 6);
    }

    function testCannotSeizeAsset_no_open_loan() public {
        // We hit the same error here as if the asset was not whitelisted
        // we still leave the test in place
        hevm.expectRevert("00040");
        lendingAuction.seizeAsset(address(mockNft), 1);
    }

    function testCannotSeizeAsset_loan_not_expired() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        // set time to one second before the loan will expire
        hevm.warp(block.timestamp + 1 days - 1);

        hevm.expectRevert("00008");
        lendingAuction.seizeAsset(address(mockNft), 1);
    }

    function testCannotSeizeAsset_loan_repaid() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        // set time to one second before the loan will expire
        hevm.warp(block.timestamp + 1 days - 1);

        daiToken.mint(address(this), 6000 ether);
        daiToken.approve(address(liquidityProviders), 6000 ether);

        lendingAuction.repayLoan(address(mockNft), 1);

        // empty lending auctions use zero asset
        hevm.expectRevert("00040");
        lendingAuction.seizeAsset(address(mockNft), 1);
    }

    function testSeizeAsset_works() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.warp(block.timestamp + 1 days);

        lendingAuction.seizeAsset(address(mockNft), 1);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, ZERO_ADDRESS);
        assertEq(loanAuction.lender, ZERO_ADDRESS);
        assertEq(loanAuction.asset, ZERO_ADDRESS);
        assertEq(loanAuction.interestRatePerSecond, 0);
        assertTrue(!loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 0);
        assertEq(loanAuction.loanEndTimestamp, 0);
        assertEq(loanAuction.lastUpdatedTimestamp, 0);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 0);

        assertEq(mockNft.ownerOf(1), LENDER_1);
    }

    function testSeizeAsset_event() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.warp(block.timestamp + 1 days);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        hevm.expectEmit(true, false, false, false);

        emit AssetSeized(address(mockNft), 1, loanAuction);

        lendingAuction.seizeAsset(address(mockNft), 1);
    }

    function testCannotRepayLoan_no_loan() public {
        hevm.expectRevert("00007");
        lendingAuction.repayLoan(address(mockNft), 1);
    }

    function testCannotRepayLoan_someone_elses_loan() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.startPrank(BORROWER_1);

        daiToken.approve(address(liquidityProviders), 6);

        hevm.expectRevert("00028");
        lendingAuction.repayLoan(offer.nftContractAddress, offer.nftId);
    }

    function testRepayLoan_works_no_interest_no_time() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6);
        daiToken.approve(address(liquidityProviders), 6);

        liquidityProviders.supplyErc20(address(daiToken), 6);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 6,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        daiToken.approve(address(liquidityProviders), 6);

        lendingAuction.repayLoan(offer.nftContractAddress, offer.nftId);
    }

    function testRepayLoan_works_with_interest() public {
        cDAIToken.setExchangeRateCurrent(220154645140434444389595003); // exchange rate of DAI at time of edit

        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 1 ether);
        daiToken.approve(address(liquidityProviders), 1 ether);

        liquidityProviders.supplyErc20(address(daiToken), 1 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444444,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 1 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.warp(block.timestamp + 12 hours + 1 seconds);

        uint256 principal = 1 ether;

        (uint256 lenderInterest, uint256 protocolInterest) = lendingAuction
            .calculateInterestAccrued(offer.nftContractAddress, offer.nftId);

        uint256 repayAmount = principal + lenderInterest + protocolInterest;

        daiToken.mint(address(this), lenderInterest + protocolInterest);

        daiToken.approve(address(liquidityProviders), repayAmount);

        lendingAuction.repayLoan(offer.nftContractAddress, offer.nftId);

        assertEq(daiToken.balanceOf(address(this)), 0);
        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)), 4678532645);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 4678532645);

        assertEq(mockNft.ownerOf(1), address(this));

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, ZERO_ADDRESS);
        assertEq(loanAuction.lender, ZERO_ADDRESS);
        assertEq(loanAuction.asset, ZERO_ADDRESS);
        assertEq(loanAuction.interestRatePerSecond, 0);
        assertTrue(!loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 0);
        assertEq(loanAuction.loanEndTimestamp, 0);
        assertEq(loanAuction.lastUpdatedTimestamp, 0);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 0);
    }

    function testRepayLoan_works_with_interest_and_protocol_interest() public {
        cDAIToken.setExchangeRateCurrent(220154645140434444389595003); // exchange rate of DAI at time of edit

        hevm.prank(OWNER);
        lendingAuction.updateProtocolInterestBps(100);

        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 1 ether);
        daiToken.approve(address(liquidityProviders), 1 ether);

        liquidityProviders.supplyErc20(address(daiToken), 1 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444444,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 1 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.warp(block.timestamp + 12 hours);

        uint256 principal = 1 ether;

        (uint256 lenderInterest, uint256 protocolInterest) = lendingAuction
            .calculateInterestAccrued(offer.nftContractAddress, offer.nftId);

        uint256 repayAmount = principal + lenderInterest + protocolInterest;

        daiToken.mint(address(this), lenderInterest + protocolInterest);

        daiToken.approve(address(liquidityProviders), repayAmount);

        LoanAuction memory loanAuction1 = lendingAuction.getLoanAuction(
            offer.nftContractAddress,
            offer.nftId
        );

        hevm.expectEmit(true, true, false, false);
        emit LoanRepaid(offer.nftContractAddress, offer.nftId, repayAmount, loanAuction1);

        lendingAuction.repayLoan(offer.nftContractAddress, offer.nftId);

        assertEq(daiToken.balanceOf(address(this)), 0);
        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)), 4678529491);
        assertEq(liquidityProviders.getCAssetBalance(OWNER, address(cDAIToken)), 22711308);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 4701240799);

        assertEq(mockNft.ownerOf(1), address(this));

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(
            offer.nftContractAddress,
            offer.nftId
        );

        assertEq(loanAuction.nftOwner, ZERO_ADDRESS);
        assertEq(loanAuction.lender, ZERO_ADDRESS);
        assertEq(loanAuction.asset, ZERO_ADDRESS);
        assertEq(loanAuction.interestRatePerSecond, 0);
        assertTrue(!loanAuction.fixedTerms);

        assertEq(loanAuction.amount, 0);
        assertEq(loanAuction.loanEndTimestamp, 0);
        assertEq(loanAuction.lastUpdatedTimestamp, 0);
        assertEq(loanAuction.accumulatedLenderInterest, 0);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 0);
    }

    function testPartialRepayLoan_works_with_interest() public {
        cDAIToken.setExchangeRateCurrent(220154645140434444389595003); // exchange rate of DAI at time of edit

        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444444,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 1 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.warp(block.timestamp + 12 hours);

        uint256 partialAmount = 0.5 ether;

        daiToken.approve(address(liquidityProviders), partialAmount);

        lendingAuction.partialRepayLoan(offer.nftContractAddress, offer.nftId, partialAmount);

        assertEq(daiToken.balanceOf(address(this)), 0.5 ether);
        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)), 24982439032);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 24982439032);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, LENDER_1);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 347222222222);
        assertTrue(!loanAuction.fixedTerms);
        assertEq(loanAuction.amount, 1 ether);
        assertEq(loanAuction.loanEndTimestamp, block.timestamp + 12 hours);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 29999999999980800);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.amountDrawn, 0.5 ether);
    }

    function testPartialRepayLoan_works_with_interest_and_protocol_interest() public {
        cDAIToken.setExchangeRateCurrent(220154645140434444389595003); // exchange rate of DAI at time of edit

        hevm.prank(OWNER);
        lendingAuction.updateProtocolInterestBps(100);

        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 6 ether);
        daiToken.approve(address(liquidityProviders), 6 ether);

        liquidityProviders.supplyErc20(address(daiToken), 6 ether);

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 694444444444,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 1 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        hevm.stopPrank();

        bytes32 offerHash = offersContract.getOfferHash(offer);

        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        hevm.warp(block.timestamp + 12 hours);

        uint256 partialAmount = 0.5 ether;

        daiToken.approve(address(liquidityProviders), partialAmount);

        lendingAuction.partialRepayLoan(offer.nftContractAddress, offer.nftId, partialAmount);

        assertEq(daiToken.balanceOf(address(this)), 0.5 ether);
        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken)), 24982439032);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 24982439032);

        assertEq(mockNft.ownerOf(1), address(lendingAuction));

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.nftOwner, address(this));
        assertEq(loanAuction.lender, LENDER_1);
        assertEq(loanAuction.asset, address(daiToken));
        assertEq(loanAuction.interestRatePerSecond, 347222222222);
        assertTrue(!loanAuction.fixedTerms);
        assertEq(loanAuction.amount, 1 ether);
        assertEq(loanAuction.loanEndTimestamp, block.timestamp + 12 hours);
        assertEq(loanAuction.lastUpdatedTimestamp, block.timestamp);
        assertEq(loanAuction.accumulatedLenderInterest, 29999999999980800);
        assertEq(loanAuction.accumulatedPaidProtocolInterest, 0);
        assertEq(loanAuction.unpaidProtocolInterest, 4999999999968000);
        assertEq(loanAuction.amountDrawn, 0.5 ether);
    }

    function testDrawLoanAmount_works() public {
        setupRefinance();

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.amountDrawn, 6 ether);

        lendingAuction.drawLoanAmount(address(mockNft), 1, 5 * 10**17);

        assertEq(daiToken.balanceOf(address(this)), 6.5 ether);

        loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.amountDrawn, 6.5 ether);
    }

    function testCannotDrawLoanAmount_funds_overdrawn() public {
        setupRefinance();

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        assertEq(loanAuction.amountDrawn, 6 ether);

        hevm.expectRevert("00020");

        lendingAuction.drawLoanAmount(address(mockNft), 1, 2 * 10**18);
    }

    function testCannotDrawLoanAmount_no_open_loan() public {
        setupRefinance();

        daiToken.mint(address(this), 10 ether);
        daiToken.approve(address(liquidityProviders), 10 ether);

        lendingAuction.repayLoan(address(mockNft), 1);

        hevm.expectRevert("00007");

        lendingAuction.drawLoanAmount(address(mockNft), 1, 2 * 10**18);
    }

    function testCannotDrawLoanAmount_not_your_loan() public {
        setupRefinance();

        hevm.expectRevert("00021");

        hevm.prank(SIGNER_1);

        lendingAuction.drawLoanAmount(address(mockNft), 1, 5 * 10**17);
    }

    function testCannotDrawLoanAmount_loan_expired() public {
        setupRefinance();

        hevm.warp(block.timestamp + 3 days);

        hevm.expectRevert("00009");

        lendingAuction.drawLoanAmount(address(mockNft), 1, 5 * 10**17);
    }

    function testRepayLoanForAccount_works() public {
        setupLoan();

        hevm.startPrank(SIGNER_1);
        daiToken.mint(address(SIGNER_1), 1000 ether);
        daiToken.approve(address(liquidityProviders), 1000 ether);

        lendingAuction.repayLoanForAccount(address(mockNft), 1, uint32(block.timestamp));
        hevm.stopPrank();
    }

    function testCannotRepayLoanForAccount_if_sanctioned() public {
        setupLoan();

        hevm.startPrank(SANCTIONED_ADDRESS);
        daiToken.mint(address(SANCTIONED_ADDRESS), 1000 ether);
        daiToken.approve(address(liquidityProviders), 1000 ether);

        hevm.expectRevert("00017");

        lendingAuction.repayLoanForAccount(address(mockNft), 1, uint32(block.timestamp));
    }

    function testCannotRefinanceByLender_when_frontrunning_happens() public {
        // Note: Borrower and Lender 1 are colluding throughout
        // to extract fees from Lender 2

        // Also Note: assuming DAI has decimals 18 throughout
        // even though the real version has decimals 6
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 10 ether);
        daiToken.approve(address(liquidityProviders), 10 ether);
        liquidityProviders.supplyErc20(address(daiToken), 10 ether);

        // Lender 1 has 10 DAI
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            10 ether
        );

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 1 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.stopPrank();

        // Borrower executes loan
        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        // Lender 1 has 1 fewer DAI, i.e., 9
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            9 ether
        );

        // Warp ahead 12 hours
        hevm.warp(block.timestamp + 12 hours);

        // Lender 2 wants to refinance.
        // Given the current loan, they only expect
        // to pay an origination fee relative to 1 DAI draw amount
        // and no gas griefing fee
        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 10 ether);
        daiToken.approve(address(liquidityProviders), 10 ether);

        liquidityProviders.supplyErc20(address(daiToken), 10 ether);
        hevm.stopPrank();

        // Lender 1 decides to frontrun Lender 2,
        // thereby 9x'ing the origination fee
        // and adding a gas griefing fee
        hevm.startPrank(LENDER_1);
        Offer memory frontrunner = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 9 ether,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        lendingAuction.refinanceByLender(frontrunner, loanAuction.lastUpdatedTimestamp);

        // Lender 1 has same 9 DAI
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            9 ether
        );

        hevm.stopPrank();

        // Borrower (colluding with Lender 1 and still frontrunning Lender 2)
        // draws full amount to maximize origination fee and gas griefing fee
        // that Lender 2 will pay Lender 1
        lendingAuction.drawLoanAmount(address(mockNft), 1, 8 ether);

        // After borrower draws rest, Lender 1 has 1 DAI
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            1 ether
        );

        hevm.startPrank(LENDER_2);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 9 ether + 1,
            duration: 1 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        // Not updating loanAuction, so this should be obsolete after frontrunning

        hevm.expectRevert("00026");

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);
    }

    function testRefinanceByLender_gas_griefing_fee_works() public {
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 1 ether);
        daiToken.approve(address(liquidityProviders), 1 ether);
        liquidityProviders.supplyErc20(address(daiToken), 1 ether);

        // Lender 1 has 1 DAI
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            1 ether
        );

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 10**10,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 1 ether,
            duration: 365 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.stopPrank();

        // Borrower executes loan
        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        // Lender 1 has 1 fewer DAI, i.e., 0
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            0
        );

        // Warp ahead 10**5 seconds
        // 10**10 interest per second * 10**5 seconds = 10**15 interest
        // this is 0.001 of 10**18, which is under the gasGriefingBps of 25
        // which means there will be a gas griefing fee
        hevm.warp(block.timestamp + 10**5 seconds);

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 10 ether);
        daiToken.approve(address(liquidityProviders), 10 ether);

        liquidityProviders.supplyErc20(address(daiToken), 10 ether);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 9 ether,
            duration: 365 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);

        hevm.stopPrank();

        // Below are calculations concerning how much Lender 1 has after fees
        // Note that gas griefing fee, if appicable, means we don't add interest in this test,
        // since add whichever is greater, interest or gas griefing fee.
        uint256 principal = 1 ether;
        uint256 amtDrawn = 1 ether;
        uint256 originationFeeBps = 25;
        uint256 gasGriefingFeeBps = 25;
        uint256 MAX_BPS = 10_000;
        uint256 feesFromLender2 = ((amtDrawn * originationFeeBps) / MAX_BPS) +
            ((amtDrawn * gasGriefingFeeBps) / MAX_BPS);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            principal + feesFromLender2
        );
    }

    function testRefinanceByLender_no_gas_griefing_fee_if_sufficient_interest() public {
        // Also Note: assuming DAI has decimals 18 throughout
        // even though the real version has decimals 6
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 1 ether);
        daiToken.approve(address(liquidityProviders), 1 ether);
        liquidityProviders.supplyErc20(address(daiToken), 1 ether);

        // Lender 1 has 10 DAI
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            1 ether
        );

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 10**10,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 1 ether,
            duration: 365 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.stopPrank();

        // Borrower executes loan
        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        // Lender 1 has 1 fewer DAI, i.e., 9
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            0
        );

        // Warp ahead 10**6 seconds
        // 10**10 interest per second * 10**6 seconds = 10**16 interest
        // this is 0.01 of 10**18, which is over the gasGriefingBps of 25
        // which means there won't be a gas griefing fee
        hevm.warp(block.timestamp + 10**6 seconds);

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 10 ether);
        daiToken.approve(address(liquidityProviders), 10 ether);

        liquidityProviders.supplyErc20(address(daiToken), 10 ether);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 1,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 9 ether,
            duration: 365 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);

        hevm.stopPrank();

        // Below are calculations concerning how much Lender 1 has after fees

        uint256 principal = 1 ether;
        uint256 interest = 10**10 * 10**6;
        uint256 amtDrawn = 1 ether;
        uint256 originationFeeBps = 25;
        uint256 MAX_BPS = 10_000;
        uint256 feesFromLender2 = ((amtDrawn * originationFeeBps) / MAX_BPS);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            principal + interest + feesFromLender2
        );
    }

    function testRefinanceByLender_term_fee_works() public {
        // Also Note: assuming DAI has decimals 18 throughout
        // even though the real version has decimals 6
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 1 ether);
        daiToken.approve(address(liquidityProviders), 1 ether);
        liquidityProviders.supplyErc20(address(daiToken), 1 ether);

        // Lender 1 has 1 DAI
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            1 ether
        );

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 10_000_000_000,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 1 ether,
            duration: 365 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.stopPrank();

        // Borrower executes loan
        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        // Lender 1 has 1 fewer DAI, i.e., 0
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            0
        );

        // Protocol owner has 0
        // Would have more later if there were a term fee
        // But will still have 0 if there isn't
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(address(this), address(cDAIToken))
            ),
            0
        );

        // Warp ahead 10**6 seconds
        // 10**10 interest per second * 10**6 seconds = 10**16 interest
        // this is 0.01 of 10**18, which is over the gas griefing amount of 0.0025
        // which means there won't be a gas griefing fee
        hevm.warp(block.timestamp + 10**6 seconds);

        hevm.startPrank(LENDER_2);

        daiToken.mint(address(LENDER_2), 10 ether);
        daiToken.approve(address(liquidityProviders), 10 ether);
        liquidityProviders.supplyErc20(address(daiToken), 10 ether);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 9_974_000_000 + 1, // maximal improvment that still triggers term fee
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 1 ether,
            duration: 365 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);

        hevm.stopPrank();

        // Below are calculations concerning how much Lender 1 has after fees
        uint256 principal = 1 ether;
        uint256 interest = 10_000_000_000 * 10**6; // interest per second * seconds
        uint256 amtDrawn = 1 ether;
        uint256 originationFeeBps = 25;
        uint256 termGriefingPremiumBps = 25;
        uint256 MAX_BPS = 10_000;
        uint256 feesFromLender2 = ((amtDrawn * originationFeeBps) / MAX_BPS);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            principal + interest + feesFromLender2
        );

        // Expect term griefing fee to have gone to protocol
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(OWNER, address(cDAIToken))
            ),
            ((1 ether * termGriefingPremiumBps) / MAX_BPS)
        );
    }

    function testWithdrawCErc20_owner_withdraw() public {
        // 0.0025% term fee on 1 DAI draw amount = 0.0025 to owner
        setupOwnerDAIBalance();

        // Will withdrawal now as owner
        hevm.startPrank(OWNER);

        liquidityProviders.withdrawCErc20(address(cDAIToken), 0.0025 * 1 ether * 1 ether);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(OWNER, address(cDAIToken))
            ),
            0
        );

        // Expect 1% of have been given to Regen Collective
        assertEq(cDAIToken.balanceOf(OWNER), 0.002475 * 1 ether * 1 ether);
        assertEq(
            cDAIToken.balanceOf(liquidityProviders.regenCollectiveAddress()),
            0.000025 * 1 ether * 1 ether
        );
    }

    function testWithdrawCErc20_owner_withdraw_always_set_amount_even_if_more_requested() public {
        // 0.0025% term fee on 1 DAI draw amount = 0.0025 to owner
        setupOwnerDAIBalance();

        // Will withdrawal now as owner
        hevm.startPrank(OWNER);

        // Will only withdraw 0.0025, the 0.003 amount gets ignored
        // because it's the owner
        liquidityProviders.withdrawCErc20(address(cDAIToken), 0.003 * 1 ether * 1 ether);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(OWNER, address(cDAIToken))
            ),
            0
        );

        // Expect 1% of have been given to Regen Collective
        assertEq(cDAIToken.balanceOf(OWNER), 0.002475 * 1 ether * 1 ether);
        assertEq(
            cDAIToken.balanceOf(liquidityProviders.regenCollectiveAddress()),
            0.000025 * 1 ether * 1 ether
        );
    }

    function testWithdrawCErc20_owner_withdraw_always_set_amount_even_if_less_requested() public {
        // 0.0025% term fee on 1 DAI draw amount = 0.0025 to owner
        setupOwnerDAIBalance();

        // Will withdrawal now as owner
        hevm.startPrank(OWNER);

        // Will only withdraw 0.0025, the 0.001 amount gets ignored
        // because it's the owner
        liquidityProviders.withdrawCErc20(address(cDAIToken), 0.001 * 1 ether * 1 ether);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(OWNER, address(cDAIToken))
            ),
            0
        );

        // Expect 1% of have been given to Regen Collective
        assertEq(cDAIToken.balanceOf(OWNER), 0.002475 * 1 ether * 1 ether);
        assertEq(
            cDAIToken.balanceOf(liquidityProviders.regenCollectiveAddress()),
            0.000025 * 1 ether * 1 ether
        );
    }

    function testWithdrawErc20_owner_withdraw() public {
        // 0.0025% term fee on 1 DAI draw amount = 0.0025 to owner
        setupOwnerDAIBalance();

        // Will withdrawal now as owner
        hevm.startPrank(OWNER);

        // Will only withdraw 0.0025, the 0.001 amount gets ignored
        // because it's the owner
        liquidityProviders.withdrawErc20(address(daiToken), 0.025 * 1 ether);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(OWNER, address(cDAIToken))
            ),
            0
        );

        // Expect 1% of have been given to Regen Collective
        assertEq(daiToken.balanceOf(OWNER), 0.002475 * 1 ether);
        assertEq(
            daiToken.balanceOf(liquidityProviders.regenCollectiveAddress()),
            0.000025 * 1 ether
        );
    }

    function testWithdrawErc20_owner_withdraw_always_set_amount_even_if_more_requested() public {
        // 0.0025% term fee on 1 DAI draw amount = 0.0025 to owner
        setupOwnerDAIBalance();

        // Will withdrawal now as owner
        hevm.startPrank(OWNER);

        // Will only withdraw 0.0025, the 0.003 amount gets ignored
        // because it's the owner
        liquidityProviders.withdrawErc20(address(daiToken), 0.003 * 1 ether);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(OWNER, address(cDAIToken))
            ),
            0
        );

        // Expect 1% of have been given to Regen Collective
        assertEq(daiToken.balanceOf(OWNER), 0.002475 * 1 ether);
        assertEq(
            daiToken.balanceOf(liquidityProviders.regenCollectiveAddress()),
            0.000025 * 1 ether
        );
    }

    function testWithdrawErc20_owner_withdraw_always_set_amount_even_if_less_requested() public {
        // 0.0025% term fee on 1 DAI draw amount = 0.0025 to owner
        setupOwnerDAIBalance();

        // Will withdrawal now as owner
        hevm.startPrank(OWNER);

        // Will only withdraw 0.0025, the 0.001 amount gets ignored
        // because it's the owner
        liquidityProviders.withdrawErc20(address(daiToken), 0.001 * 1 ether);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(OWNER, address(cDAIToken))
            ),
            0
        );

        // Expect 1% of have been given to Regen Collective
        assertEq(daiToken.balanceOf(OWNER), 0.002475 * 1 ether);
        assertEq(
            daiToken.balanceOf(liquidityProviders.regenCollectiveAddress()),
            0.000025 * 1 ether
        );
    }

    function testWithdrawEth_owner_withdraw() public {
        // 0.0025% term fee on 1 ETH draw amount = 0.0025 to owner
        setupOwnerETHBalance();

        // Will withdrawal now as owner
        hevm.startPrank(OWNER);
        hevm.deal(address(liquidityProviders.regenCollectiveAddress()), 0);

        liquidityProviders.withdrawEth(0.0025 * 1 ether);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cEtherToken),
                liquidityProviders.getCAssetBalance(OWNER, address(cEtherToken))
            ),
            0
        );

        // Expect 1% of have been given to Regen Collective
        assertEq(address(OWNER).balance, 0.002475 * 1 ether);
        assertEq(address(liquidityProviders.regenCollectiveAddress()).balance, 0.000025 * 1 ether);
    }

    function testWithdrawEth_owner_withdraw_always_set_amount_even_if_more_requested() public {
        // 0.0025% term fee on 1 ETH draw amount = 0.0025 to owner
        setupOwnerETHBalance();

        // Will withdrawal now as owner
        hevm.startPrank(OWNER);
        hevm.deal(address(liquidityProviders.regenCollectiveAddress()), 0);

        // Requesting more than the 0.0025 balance
        liquidityProviders.withdrawEth(0.003 * 1 ether);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cEtherToken),
                liquidityProviders.getCAssetBalance(OWNER, address(cEtherToken))
            ),
            0
        );

        // Expect 1% of have been given to Regen Collective
        assertEq(address(OWNER).balance, 0.002475 * 1 ether);
        assertEq(address(liquidityProviders.regenCollectiveAddress()).balance, 0.000025 * 1 ether);
    }

    function testWithdrawEth_owner_withdraw_always_set_amount_even_if_less_requested() public {
        // 0.0025% term fee on 1 ETH draw amount = 0.0025 to owner
        setupOwnerETHBalance();

        // Will withdrawal now as owner
        hevm.startPrank(OWNER);
        hevm.deal(address(liquidityProviders.regenCollectiveAddress()), 0);

        // Requesting less than the 0.0025 balance
        liquidityProviders.withdrawEth(0.001 * 1 ether);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cEtherToken),
                liquidityProviders.getCAssetBalance(OWNER, address(cEtherToken))
            ),
            0
        );

        // Expect 1% of have been given to Regen Collective
        assertEq(address(OWNER).balance, 0.002475 * 1 ether);
        assertEq(address(liquidityProviders.regenCollectiveAddress()).balance, 0.000025 * 1 ether);
    }

    function testRefinanceByLender_no_term_fee_if_sufficient_improvement() public {
        // Also Note: assuming DAI has decimals 18 throughout
        // even though the real version has decimals 6
        hevm.startPrank(LENDER_1);
        daiToken.mint(address(LENDER_1), 1 ether);
        daiToken.approve(address(liquidityProviders), 1 ether);
        liquidityProviders.supplyErc20(address(daiToken), 1 ether);

        // Lender 1 has 1 DAI
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            1 ether
        );

        Offer memory offer = Offer({
            creator: LENDER_1,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 10_000_000_000,
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 1 ether,
            duration: 365 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        offersContract.createOffer(offer);

        bytes32 offerHash = offersContract.getOfferHash(offer);

        hevm.stopPrank();

        // Borrower executes loan
        lendingAuction.executeLoanByBorrower(
            offer.nftContractAddress,
            offer.nftId,
            offerHash,
            offer.floorTerm
        );

        // Lender 1 has 1 fewer DAI, i.e., 0
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            0
        );

        // Protocol owner has 0
        // Would have more later if there were a term fee
        // But will still have 0 if there isn't
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(address(this), address(cDAIToken))
            ),
            0
        );

        // Warp ahead 10**6 seconds
        // 10**10 interest per second * 10**6 seconds = 10**16 interest
        // this is 0.01 of 10**18, which is over the gas griefing amount of 0.0025
        // which means there won't be a gas griefing fee
        hevm.warp(block.timestamp + 10**6 seconds);

        hevm.startPrank(LENDER_2);
        daiToken.mint(address(LENDER_2), 10 ether);
        daiToken.approve(address(liquidityProviders), 10 ether);

        liquidityProviders.supplyErc20(address(daiToken), 10 ether);

        Offer memory offer2 = Offer({
            creator: LENDER_2,
            nftContractAddress: address(mockNft),
            interestRatePerSecond: 9_974_000_000, // minimal improvment to avoid term griefing
            fixedTerms: false,
            floorTerm: false,
            lenderOffer: true,
            nftId: 1,
            asset: address(daiToken),
            amount: 1 ether,
            duration: 365 days,
            expiration: uint32(block.timestamp + 1),
            floorTermLimit: 1
        });

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);

        lendingAuction.refinanceByLender(offer2, loanAuction.lastUpdatedTimestamp);

        hevm.stopPrank();

        // Below are calculations concerning how much Lender 1 has after fees

        uint256 principal = 1 ether;
        uint256 interest = 10_000_000_000 * 10**6 seconds; // interest per second * seconds
        uint256 amtDrawn = 1 ether;
        uint256 originationFeeBps = 25;
        uint256 MAX_BPS = 10_000;
        uint256 feesFromLender2 = ((amtDrawn * originationFeeBps) / MAX_BPS);

        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(LENDER_1, address(cDAIToken))
            ),
            principal + interest + feesFromLender2
        );

        // Expect no term griefing fee to have gone to protocol
        assertEq(
            liquidityProviders.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidityProviders.getCAssetBalance(OWNER, address(cDAIToken))
            ),
            0
        );
    }

    function testDrawLoanAmount_slashUnsupportedAmount_works() public {
        setupRefinance();

        //increase block.timestamp to accumulate interest
        hevm.warp(block.timestamp + 12 hours);

        hevm.prank(LENDER_2);
        liquidityProviders.withdrawErc20(address(daiToken), 0.9 ether);

        LoanAuction memory loanAuction = lendingAuction.getLoanAuction(address(mockNft), 1);
        (uint256 lenderInterest, ) = lendingAuction.calculateInterestAccrued(address(mockNft), 1);
        uint256 lenderBalanceBefore = liquidityProviders.getCAssetBalance(
            LENDER_2,
            address(cDAIToken)
        );

        assertEq(lenderInterest, 29999999999980800);
        assertEq(loanAuction.amountDrawn, 6 ether);
        assertTrue(loanAuction.lenderRefi);
        assertEq(lenderBalanceBefore, 1055000000000019200000000000000000000);

        lendingAuction.drawLoanAmount(address(mockNft), 1, 1 ether);

        LoanAuction memory loanAuctionAfter = lendingAuction.getLoanAuction(address(mockNft), 1);
        (uint256 lenderInterestAfter, ) = lendingAuction.calculateInterestAccrued(
            address(mockNft),
            1
        );
        uint256 lenderBalanceAfter = liquidityProviders.getCAssetBalance(
            LENDER_2,
            address(cDAIToken)
        );

        assertEq(lenderInterestAfter, 0);
        assertEq(lenderBalanceAfter, 55000000000019200000000000000000000);
        // balance of the borrower
        assertEq(daiToken.balanceOf(address(this)), 7000000000000000000);
        // we expect the amountDrawn to be 6.04x ether. This is the remaining balance of the lender plus the current amountdrawn
        assertEq(loanAuctionAfter.amountDrawn, 7000000000000000000);
        assertTrue(!loanAuctionAfter.lenderRefi);
    }
}
