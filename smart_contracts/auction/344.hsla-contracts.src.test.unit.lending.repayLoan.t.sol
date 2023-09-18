// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";

contract TestRepayLoan is Test, OffersLoansRefinancesFixtures {
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

    function test_fuzz_repayLoan_simplest_case(
        FuzzedOfferFields memory fuzzedOffer,
        uint16 secondsBeforeRepayment
    ) public validateFuzzedOfferFields(fuzzedOffer) {
        Offer memory offerToCreate = offerStructFromFields(fuzzedOffer, defaultFixedOfferFields);

        (Offer memory offer, ) = createOfferAndTryToExecuteLoanByBorrower(
            offerToCreate,
            "should work"
        );

        LoanAuction memory loanAuction = lending.getLoanAuction(
            defaultFixedOfferFields.nftContractAddress,
            defaultFixedOfferFields.nftId
        );

        assertionsForExecutedLoan(offer);

        vm.warp(block.timestamp + secondsBeforeRepayment);

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

        uint256 interest = (offer.interestRatePerSecond * secondsBeforeRepayment) +
            protocolInterest;

        if (offer.asset == address(daiToken)) {
            // Give borrower enough to pay interest
            mintDai(borrower1, interest + interestDelta);

            uint256 liquidityBalanceBeforeRepay = cDAIToken.balanceOf(address(liquidity));

            vm.startPrank(borrower1);
            daiToken.approve(address(liquidity), ~uint256(0));
            lending.repayLoan(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId
            );
            vm.stopPrank();

            // Liquidity contract cToken balance
            assertEq(
                cDAIToken.balanceOf(address(liquidity)),
                liquidityBalanceBeforeRepay +
                    liquidity.assetAmountToCAssetAmount(
                        address(daiToken),
                        offer.amount + interest + interestDelta
                    )
            );

            // Borrower back to 0
            assertEq(daiToken.balanceOf(address(borrower1)), 0);

            // Lender back with interest
            assertCloseEnough(
                defaultDaiLiquiditySupplied + interest + interestDelta,
                assetBalance(lender1, address(daiToken)),
                assetBalancePlusOneCToken(lender1, address(daiToken))
            );
        } else {
            uint256 liquidityBalanceBeforeRepay = cEtherToken.balanceOf(address(liquidity));

            vm.startPrank(borrower1);
            vm.expectRevert("00030");
            //  subtract 1 in order to fail when 0 interest
            lending.repayLoan{ value: loanAuction.amountDrawn - 1 }(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId
            );

            lending.repayLoan{ value: loanAuction.amountDrawn + interest + interestDelta }(
                defaultFixedOfferFields.nftContractAddress,
                defaultFixedOfferFields.nftId
            );
            vm.stopPrank();

            // Liquidity contract cToken balance
            assertEq(
                cEtherToken.balanceOf(address(liquidity)),
                liquidityBalanceBeforeRepay +
                    liquidity.assetAmountToCAssetAmount(
                        address(ETH_ADDRESS),
                        offer.amount + interest + interestDelta
                    )
            );

            // Borrower back to initial minus interest
            assertEq(
                address(borrower1).balance,
                defaultInitialEthBalance - (interest + interestDelta)
            );

            // Lender back with interest
            assertCloseEnough(
                defaultEthLiquiditySupplied + interest + interestDelta,
                assetBalance(lender1, address(ETH_ADDRESS)),
                assetBalancePlusOneCToken(lender1, address(ETH_ADDRESS))
            );
        }
    }
}
