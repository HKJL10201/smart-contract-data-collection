// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20Upgradeable.sol";
import "../../interfaces/compound/ICERC20.sol";
import "../../interfaces/compound/ICEther.sol";
import "../../Lending.sol";
import "../../Liquidity.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IWETH.sol";
import "../mock/ERC721Mock.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../common/BaseTest.sol";

// @dev These tests are intended to be run against a forked mainnet.

//  TODO Comment each line of testing for readability by auditors

// TODO(Refactor/deduplicate with LiquidityProviders testing)
contract TestLendingAuctionIntegrationTest is BaseTest, ERC721HolderUpgradeable {
    IUniswapV2Router SushiSwapRouter;
    ERC721Mock mockNFT;
    IWETH WETH;
    IERC20Upgradeable DAI;
    ICERC20 cDAI;
    ICEther cETH;
    NiftyApesLending LA;
    NiftyApesLiquidity liquidityProviders;
    address compContractAddress = 0xbbEB7c67fa3cfb40069D19E598713239497A3CA5;
    uint256 immutable pk = 0x60b919c82f0b4791a5b7c6a7275970ace1748759ebdaa4076d7eeed9dbcff3c3;
    address immutable signer = 0x503408564C50b43208529faEf9bdf9794c015d52;

    //address immutable caller = ;

    function setUp() public {
        // Setup WETH
        WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        // Setup DAI
        DAI = IERC20Upgradeable(0x6B175474E89094C44Da98b954EedeAC495271d0F);

        // Setup SushiSwapRouter
        SushiSwapRouter = IUniswapV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

        // Setup cETH and balances
        cETH = ICEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
        // Mint some cETH
        cETH.mint{ value: 10 ether }();

        // Setup DAI balances

        // There is another way to do this using HEVM cheatcodes like so:
        //
        // IEVM.store(address(DAI), 0xde88c4128f6243399c8c224ee49c9683b554a068089998cb8cf2b7c8a19de28d, bytes32(uint256(100000 ether)));
        //
        // but I didn't figure out how to easily calculate the
        // storage addresses for the deployed test contracts or approvals, so I just used a deployed router.

        // So, we get some DAI with Sushiswap.
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(DAI);
        // Let's trade for 100k dai
        SushiSwapRouter.swapExactETHForTokens{ value: 1000000 ether }(
            1000 ether,
            path,
            address(this),
            block.timestamp + 1000
        );

        // Setup cDAI and balances
        // Point at the real compound DAI token deployment
        cDAI = ICERC20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
        // Mint 25 ether in cDAI
        DAI.approve(address(cDAI), 500000 ether);
        cDAI.mint(500000 ether);

        // Setup the liquidity providers contract
        LA = new NiftyApesLending();

        liquidityProviders = new NiftyApesLiquidity();
        liquidityProviders.initialize(compContractAddress);

        // Allow assets for testing
        liquidityProviders.setCAssetAddress(address(DAI), address(cDAI));
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cETH)
        );
        uint256 max = type(uint256).max;

        // Setup mock NFT
        mockNFT = new ERC721Mock();
        mockNFT.initialize("BoredApe", "BAYC");

        // Give this contract some
        mockNFT.safeMint(address(this), 0);

        // Give the signer some
        mockNFT.safeMint(signer, 1);

        hevm.startPrank(signer, signer);
        mockNFT.approve(address(LA), 1);
        hevm.stopPrank();

        // Approve spends
        DAI.approve(address(LA), max);
        cDAI.approve(address(LA), max);
        cETH.approve(address(LA), max);

        // Supply to 200k DAI contract
        liquidityProviders.supplyErc20(address(DAI), 200000 ether);
        // Supply 10 ether to contract
        liquidityProviders.supplyEth{ value: 10 ether }();
    }

    // Test Cases

    // function testUpdateLoanDrawProtocolFee() public {
    //     LA.updateLoanDrawProtocolFee(30);
    //     assert(LA.loanDrawFeeProtocolBps() == 30);
    // }

    // function testUpdateRefinancePremiumLenderFee() public {
    //     LA.updateRefinancePremiumLenderFee(30);
    //     assert(LA.refinancePremiumLenderBps() == 30);
    // }

    // function testUpdateRefinancePremiumProtocolFee() public {
    //     LA.updateRefinancePremiumProtocolFee(30);
    //     assert(LA.refinancePremiumProtocolBps() == 30);
    // }

    // function testCreateGetandRemoveOffer(bool fixedTerms, bool floorTerm) public {
    //     // Create a floor offer
    //     LendingAuction.Offer memory offer;
    //     offer.creator = address(this);
    //     offer.nftContractAddress = address(mockNFT);
    //     offer.nftId = 0;
    //     offer.asset = address(DAI);
    //     offer.amount = 25000 ether;
    //     offer.interestRateBps = 1000;
    //     offer.duration = 172800;
    //     offer.expiration = block.timestamp + 1000000;
    //     offer.fixedTerms = fixedTerms;
    //     offer.floorTerm = floorTerm;

    //     bytes32 create_hash = LA.getOfferHash(offer);

    //     LA.createOffer(offer);

    //     LendingAuction.Offer memory get_offer = LA.getOffer(
    //         address(mockNFT),
    //         0,
    //         create_hash,
    //         floorTerm
    //     );

    //     assert(LA.getOfferHash(get_offer) == create_hash);

    //     // And remove it
    //     LA.removeOffer(address(mockNFT), 0, create_hash, floorTerm);

    //     // test that offer has been removed
    //     LendingAuction.Offer memory get_offer_2 = LA.getOffer(
    //         address(mockNFT),
    //         0,
    //         create_hash,
    //         floorTerm
    //     );

    //     assert(get_offer_2.creator == address(0));
    //     assert(get_offer_2.nftContractAddress == address(0));
    //     assert(get_offer_2.nftId == 0);
    //     assert(get_offer_2.asset == address(0));
    //     assert(get_offer_2.amount == 0 ether);
    //     assert(get_offer_2.interestRateBps == 0);
    //     assert(get_offer_2.duration == 0);
    //     assert(get_offer_2.expiration == 0);
    //     assert(get_offer_2.fixedTerms == false);
    //     assert(get_offer_2.floorTerm == false);
    // }

    // function testSize(
    //     address nftContractAddress,
    //     uint256 nftId,
    //     bool floorTerm
    // ) public {
    //     assert(0 == LA.size(nftContractAddress, nftId, floorTerm));
    // }

    // // TODO(This should pass)
    // // function testExecuteLoanAndRefinance(
    // //     bool fixedTerms,
    // //     bool floorTerm,
    // //     bool lender
    // // ) public {
    // //     // Create a floor offer
    // //     LendingAuction.Offer memory offer;
    // //     offer.creator = address(this);
    // //     offer.nftContractAddress = address(mockNFT);
    // //     offer.nftId = 0;
    // //     offer.asset = address(DAI);
    // //     offer.amount = 25000 ether;
    // //     offer.interestRateBps = 1000;
    // //     offer.duration = 172800;
    // //     offer.expiration = block.timestamp + 1000000;
    // //     offer.fixedTerms = fixedTerms;
    // //     offer.floorTerm = floorTerm;

    // //     bytes32 create_hash = LA.getOfferHash(offer);

    // //     LA.createOffer(offer);

    // //     bytes32 created_hash = LA.getOfferHash(
    // //         LA.getOffer(address(mockNFT), 0, create_hash, floorTerm)
    // //     );

    // //     // Check that get offer worked
    // //     assert(create_hash == created_hash);

    // //     created_hash = LA.getOfferHash(LA.getOfferAtIndex(address(mockNFT), 0, 0, floorTerm));

    // //     // Check that get offer worked
    // //     assert(create_hash == created_hash);

    // //     mockNFT.approve(address(LA), 0);

    // //     // TODO create fail cases for each require statement.
    // //     // TODO assert statements to check math.

    // //     if (lender) {
    // //         LA.executeLoanByLender(address(mockNFT), floorTerm, 0, create_hash);
    // //     } else {
    // //         LA.executeLoanByBorrower(address(mockNFT), 0, create_hash, floorTerm);
    // //     }

    // //     // Let's move forward in time and blocks
    // //     hevm.warp(block.number + 1000);
    // //     hevm.roll(block.timestamp + 10000);

    // //     LA.getLoanAuction(address(mockNFT), 0);

    // //     // Create a new offer

    // //     offer.interestRateBps = offer.interestRateBps / 10;
    // //     offer.amount += 1000 ether;

    // //     create_hash = LA.getOfferHash(offer);

    // //     LA.createOffer(offer);

    // //     if (!offer.fixedTerms) {
    // //         // Test refinance
    // //         if (lender) {
    // //             // TODO(Fix arithmetic overflows)
    // //             LA.refinanceByLender(offer);
    // //         } else {
    // //             LA.refinanceByBorrower(
    // //                 offer.nftContractAddress,
    // //                 offer.floorTerm,
    // //                 offer.nftId,
    // //                 create_hash
    // //             );
    // //         }
    // //     }
    // // }

    // function testGetOfferSigner() public {
    //     LendingAuction.Offer memory offer;
    //     offer.creator = address(this);
    //     offer.nftContractAddress = address(mockNFT);
    //     offer.nftId = 0;
    //     offer.asset = address(DAI);
    //     offer.amount = 25000 ether;
    //     offer.interestRateBps = 1000;
    //     offer.duration = 172800;
    //     offer.expiration = block.timestamp + 1000000;
    //     offer.fixedTerms = false;
    //     offer.floorTerm = false;

    //     // This is the EIP712 signed hash
    //     bytes32 encoded_offer = LA.getEIP712EncodedOffer(offer);

    //     uint8 v;
    //     bytes32 r;
    //     bytes32 s;
    //     (v, r, s) = hevm.sign(pk, encoded_offer);

    //     bytes memory signature = "";

    //     // case 65: r,s,v signature (standard)
    //     assembly {
    //         // Logical shift left of the value
    //         mstore(add(signature, 0x20), r)
    //         mstore(add(signature, 0x40), s)
    //         mstore(add(signature, 0x60), shl(248, v))
    //         // 65 bytes long
    //         mstore(signature, 0x41)
    //         // Update free memory pointer
    //         mstore(0x40, add(signature, 0x80))
    //     }

    //     assert(signer == LA.getOfferSigner(encoded_offer, signature));
    // }

    // function testWithdrawOfferSignature() public {
    //     LendingAuction.Offer memory offer;
    //     offer.creator = address(this);
    //     offer.nftContractAddress = address(mockNFT);
    //     offer.nftId = 0;
    //     offer.asset = address(DAI);
    //     offer.amount = 25000 ether;
    //     offer.interestRateBps = 1000;
    //     offer.duration = 172800;
    //     offer.expiration = block.timestamp + 1000000;
    //     offer.fixedTerms = false;
    //     offer.floorTerm = false;

    //     // This is the EIP712 signed hash
    //     bytes32 encoded_offer = LA.getEIP712EncodedOffer(offer);

    //     uint8 v;
    //     bytes32 r;
    //     bytes32 s;
    //     (v, r, s) = hevm.sign(pk, encoded_offer);

    //     bytes memory signature = "";

    //     // case 65: r,s,v signature (standard)
    //     assembly {
    //         // Logical shift left of the value
    //         mstore(add(signature, 0x20), r)
    //         mstore(add(signature, 0x40), s)
    //         mstore(add(signature, 0x60), shl(248, v))
    //         // 65 bytes long
    //         mstore(signature, 0x41)
    //         // Update free memory pointer
    //         mstore(0x40, add(signature, 0x80))
    //     }

    //     hevm.prank(signer, signer);
    //     LA.withdrawOfferSignature(address(mockNFT), 0, encoded_offer, signature);

    //     assert(LA.getOfferSignatureStatus(signature) == true);
    // }

    // function testExecuteLoanByLenderSignature() public {
    //     LendingAuction.Offer memory offer;
    //     offer.creator = signer;
    //     offer.nftContractAddress = address(mockNFT);
    //     offer.nftId = 1;
    //     offer.asset = address(DAI);
    //     offer.amount = 25000 ether;
    //     offer.interestRateBps = 1000;
    //     offer.duration = 172800;
    //     offer.expiration = block.timestamp + 1000000;
    //     offer.fixedTerms = false;
    //     offer.floorTerm = false;

    //     bytes32 encoded_offer = LA.getEIP712EncodedOffer(offer);

    //     uint8 v;
    //     bytes32 r;
    //     bytes32 s;
    //     (v, r, s) = hevm.sign(pk, encoded_offer);

    //     bytes memory signature = "";

    //     assembly {
    //         // Logical shift left of the value
    //         mstore(add(signature, 0x20), r)
    //         mstore(add(signature, 0x40), s)
    //         mstore(add(signature, 0x60), shl(248, v))
    //         // 65 bytes long
    //         mstore(signature, 0x41)
    //         // Update free memory pointer
    //         mstore(0x40, add(signature, 0x80))
    //     }

    //     // TODO add fail cases to test each require statement.
    //     LA.executeLoanByLenderSignature(offer, signature);

    //     // TODO add assert statement that checks the executed loan for correctness
    // }

    // function testExecuteLoanByBorrowerSignature() public {
    //     LendingAuction.Offer memory offer;
    //     offer.creator = signer;
    //     offer.nftContractAddress = address(mockNFT);
    //     offer.nftId = 0;
    //     offer.asset = address(DAI);
    //     offer.amount = 1000 ether;
    //     offer.interestRateBps = 1000;
    //     offer.duration = 172800;
    //     offer.expiration = block.timestamp + 1000000;
    //     offer.fixedTerms = false;
    //     offer.floorTerm = false;

    //     DAI.transfer(signer, 10000 ether);
    //     hevm.startPrank(signer, signer);
    //     DAI.approve(address(LA), type(uint256).max);
    //     LA.supplyErc20(address(DAI), 10000 ether);
    //     hevm.stopPrank();

    //     mockNFT.approve(address(LA), 0);

    //     bytes32 encoded_offer = LA.getEIP712EncodedOffer(offer);

    //     uint8 v;
    //     bytes32 r;
    //     bytes32 s;
    //     (v, r, s) = hevm.sign(pk, encoded_offer);

    //     bytes memory signature = "";

    //     assembly {
    //         // Logical shift left of the value
    //         mstore(add(signature, 0x20), r)
    //         mstore(add(signature, 0x40), s)
    //         mstore(add(signature, 0x60), shl(248, v))
    //         // 65 bytes long
    //         mstore(signature, 0x41)
    //         // Update free memory pointer
    //         mstore(0x40, add(signature, 0x80))
    //     }
    //     // TODO add fail cases to test each require statement.

    //     LA.executeLoanByBorrowerSignature(offer, signature, 0);

    //     // TODO add assert statement that checks the executed loan for correctness
    // }

    // // function testDrawLoan(bool floorTerm, bool lender) public {
    // //     // Create a floor offer
    // //     LendingAuction.Offer memory offer;
    // //     offer.creator = address(this);
    // //     offer.nftContractAddress = address(mockNFT);
    // //     offer.nftId = 0;
    // //     offer.asset = address(DAI);
    // //     offer.amount = 25000 ether;
    // //     offer.interestRateBps = 1000;
    // //     offer.duration = 172800;
    // //     offer.expiration = block.timestamp + 1000000;
    // //     offer.fixedTerms = false;
    // //     offer.floorTerm = floorTerm;

    // //     bytes32 create_hash = LA.getOfferHash(offer);

    // //     LA.createOffer(offer);

    // //     bytes32 created_hash = LA.getOfferHash(
    // //         LA.getOffer(address(mockNFT), 0, create_hash, floorTerm)
    // //     );

    // //     // Check that get offer worked
    // //     assert(create_hash == created_hash);

    // //     created_hash = LA.getOfferHash(LA.getOfferAtIndex(address(mockNFT), 0, 0, floorTerm));

    // //     // Check that get offer worked
    // //     assert(create_hash == created_hash);

    // //     mockNFT.approve(address(LA), 0);

    // //     if (lender) {
    // //         LA.executeLoanByLender(address(mockNFT), floorTerm, 0, create_hash);
    // //     } else {
    // //         LA.executeLoanByBorrower(address(mockNFT), 0, create_hash, floorTerm);
    // //     }

    // //     offer.creator = address(this);
    // //     offer.nftContractAddress = address(mockNFT);
    // //     offer.nftId = 0;
    // //     offer.asset = address(DAI);
    // //     offer.amount = 35000 ether;
    // //     offer.interestRateBps = 100;
    // //     offer.duration = 272800;
    // //     offer.expiration = block.timestamp + 1000000;
    // //     offer.fixedTerms = false;
    // //     offer.floorTerm = floorTerm;

    // //     // TODO add assert statement that checks the refinanced loan for correctness
    // //     // TODO add fail cases to test each require statement.
    // //     // TODO assert statements to check math.

    // //     LA.refinanceByLender(offer);

    // //     // TODO add assert statement that checks the additional time for correctness
    // //     // TODO add fail cases to test each require statement.

    // //     // this should not longer have an issue
    // //     LA.drawLoanTime(address(mockNFT), 0, 10000);

    // //     // TODO add assert statement that checks the additional amount for correctness
    // //     // TODO add fail cases to test each require statement.

    // //     // This amount should also be denominated in the unwrapped asset address.
    // //     // this is denominated in the asset of the loan
    // //     LA.drawLoanAmount(address(mockNFT), 0, 5000 ether);
    // // }

    // function testRepayRemainingLoan(bool floorTerm) public {
    //     // Create a floor offer
    //     LendingAuction.Offer memory offer;
    //     offer.creator = address(this);
    //     offer.nftContractAddress = address(mockNFT);
    //     offer.nftId = 0;
    //     offer.asset = address(DAI);
    //     offer.amount = 25000 ether;
    //     offer.interestRateBps = 1000;
    //     offer.duration = 172800;
    //     offer.expiration = block.timestamp + 1000000;
    //     offer.fixedTerms = false;
    //     offer.floorTerm = floorTerm;

    //     bytes32 create_hash = LA.getOfferHash(offer);

    //     LA.createOffer(offer);

    //     mockNFT.approve(address(LA), 0);

    //     LA.executeLoanByLender(address(mockNFT), floorTerm, 0, create_hash);

    //     // So, we get some DAI with Sushiswap.
    //     address[] memory path = new address[](2);
    //     path[0] = address(WETH);
    //     path[1] = address(DAI);

    //     // TODO(Success assertions)
    //     LA.repayRemainingLoan(address(mockNFT), 0);
    // }

    // // function testPartialPayment(bool floorTerm) public {
    // //     // Create a floor offer
    // //     LendingAuction.Offer memory offer;
    // //     offer.creator = address(this);
    // //     offer.nftContractAddress = address(mockNFT);
    // //     offer.nftId = 0;
    // //     offer.asset = address(DAI);
    // //     offer.amount = 25000 ether;
    // //     offer.interestRateBps = 1000;
    // //     offer.duration = 172800;
    // //     offer.expiration = block.timestamp + 1000000;
    // //     offer.fixedTerms = false;
    // //     offer.floorTerm = floorTerm;

    // //     bytes32 create_hash = LA.getOfferHash(offer);

    // //     // TODO(Success assertions)
    // //     LA.createOffer(offer);

    // //     mockNFT.approve(address(LA), 0);

    // //     LA.executeLoanByLender(address(mockNFT), floorTerm, 0, create_hash);

    // //     LA.partialPayment(address(mockNFT), 0, 10000 ether);
    // // }

    // function testSeizeAsset() public {
    //     LendingAuction.Offer memory offer;
    //     offer.creator = address(this);
    //     offer.nftContractAddress = address(mockNFT);
    //     offer.nftId = 0;
    //     offer.asset = address(DAI);
    //     offer.amount = 25000 ether;
    //     offer.interestRateBps = 1000;
    //     offer.duration = 172800;
    //     offer.expiration = block.timestamp + 1000000;
    //     offer.fixedTerms = false;
    //     offer.floorTerm = false;

    //     bytes32 create_hash = LA.getOfferHash(offer);

    //     LA.createOffer(offer);

    //     mockNFT.approve(address(LA), 0);

    //     LA.executeLoanByLender(address(mockNFT), false, 0, create_hash);

    //     hevm.warp(block.timestamp + 172801);

    //     LA.seizeAsset(address(mockNFT), 0);
    // }

    // function testCalculations(
    //     uint64 amount,
    //     uint64 interestRateBps,
    //     uint64 duration
    // ) public {
    //     if (duration < 86401) {
    //         duration += uint32(86401);
    //     }
    //     // TODO(Otherwise compound math fails at some point)
    //     // @alcibiades How should this TODO be addressed?
    //     if (amount < 1 ether) {
    //         amount += 1 ether;
    //     }

    //     LendingAuction.Offer memory offer;
    //     offer.creator = address(this);
    //     offer.nftContractAddress = address(mockNFT);
    //     offer.nftId = 0;
    //     offer.asset = address(DAI);
    //     offer.amount = amount;
    //     offer.interestRateBps = interestRateBps;
    //     offer.duration = duration;
    //     offer.expiration = block.timestamp + 1000000;
    //     offer.fixedTerms = false;
    //     offer.floorTerm = false;

    //     bytes32 create_hash = LA.getOfferHash(offer);

    //     LA.createOffer(offer);

    //     mockNFT.approve(address(LA), 0);

    //     LA.executeLoanByLender(address(mockNFT), false, 0, create_hash);

    //     // Warp to right before it expires
    //     hevm.warp(block.timestamp + (duration - 1));
    //     hevm.roll(block.number + 1000);

    //     // TODO(Add assertion about expected value after conversion of rate to basis points)
    //     LA.calculateInterestAccrued(address(mockNFT), 0);

    //     // TODO(Add assertion)
    //     LA.calculateFullRepayment(address(mockNFT), 0);

    //     // TODO(Add assertion)
    //     LA.calculateFullRefinanceByLender(address(mockNFT), 0);
    // }
}
