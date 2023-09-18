// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestUpdateGasGriefingProtocolPremiumBps is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    // This functionality has been removed from the v1 contracts

    // function _test_updateGasGriefingProtocolPremiumBps_works(
    //     FuzzedOfferFields memory fuzzed,
    //     uint16 secondsBeforeRefinance,
    //     uint16 updatedGasGriefingProtocolPremiumAmount
    // ) private {
    //     vm.startPrank(owner);
    //     lending.updateGasGriefingProtocolPremiumBps(updatedGasGriefingProtocolPremiumAmount);
    //     vm.stopPrank();

    //     assertEq(lending.gasGriefingProtocolPremiumBps(), updatedGasGriefingProtocolPremiumAmount);

    //     Offer memory offer = offerStructFromFields(fuzzed, defaultFixedOfferFields);
    //     (, LoanAuction memory firstLoan) = createOfferAndTryToExecuteLoanByBorrower(
    //         offer,
    //         "should work"
    //     );

    //     // new offer from lender2 with +1 amount
    //     // will trigger term griefing and gas griefing
    //     defaultFixedOfferFields.creator = lender2;
    //     fuzzed.duration = fuzzed.duration + 1; // make sure offer is better
    //     fuzzed.floorTerm = false; // refinance can't be floor term
    //     fuzzed.expiration = uint32(block.timestamp) + secondsBeforeRefinance + 1;
    //     Offer memory newOffer = offerStructFromFields(fuzzed, defaultFixedOfferFields);

    //     vm.warp(block.timestamp + secondsBeforeRefinance);

    //     tryToRefinanceByLender(newOffer, "should work");

    //     uint256 interest = offer.interestRatePerSecond * secondsBeforeRefinance;

    //     uint256 threshold = (lending.gasGriefingPremiumBps() * firstLoan.amountDrawn) / MAX_BPS;

    //     // uint256 griefingToLender = threshold - interest;

    //     uint256 gasGriefingToProtocol = (interest * lending.gasGriefingProtocolPremiumBps()) /
    //         MAX_BPS;

    //     uint256 termGriefingToProtocol = (lending.termGriefingPremiumBps() *
    //         firstLoan.amountDrawn) / MAX_BPS;

    //     if (offer.asset == address(daiToken)) {
    //         if (interest < threshold) {
    //             assertBetween(
    //                 gasGriefingToProtocol + termGriefingToProtocol,
    //                 assetBalance(owner, address(daiToken)),
    //                 assetBalancePlusOneCToken(owner, address(daiToken))
    //             );
    //         } else {
    //             assertBetween(
    //                 termGriefingToProtocol,
    //                 assetBalance(owner, address(daiToken)),
    //                 assetBalancePlusOneCToken(owner, address(daiToken))
    //             );
    //         }
    //     } else {
    //         if (interest < threshold) {
    //             assertBetween(
    //                 gasGriefingToProtocol + termGriefingToProtocol,
    //                 assetBalance(owner, ETH_ADDRESS),
    //                 assetBalancePlusOneCToken(owner, ETH_ADDRESS)
    //             );
    //         } else {
    //             assertBetween(
    //                 termGriefingToProtocol,
    //                 assetBalance(owner, ETH_ADDRESS),
    //                 assetBalancePlusOneCToken(owner, ETH_ADDRESS)
    //             );
    //         }
    //     }
    // }

    // function test_fuzz_updateGasGriefingProtocolPremiumBps_works(
    //     FuzzedOfferFields memory fuzzedOffer,
    //     uint16 secondsBeforeRefinance,
    //     uint16 updatedGasGriefingProtocolPremiumAmount
    // ) public validateFuzzedOfferFields(fuzzedOffer) {
    //     vm.assume(updatedGasGriefingProtocolPremiumAmount < MAX_BPS);

    //     _test_updateGasGriefingProtocolPremiumBps_works(
    //         fuzzedOffer,
    //         secondsBeforeRefinance,
    //         updatedGasGriefingProtocolPremiumAmount
    //     );
    // }

    // function test_unit_updateGasGriefingProtocolPremiumBps_works() public {
    //     uint16 secondsBeforeRefinance = 300;
    //     uint16 updatedGasGriefingProtocolPremiumAmount = 5000;

    //     _test_updateGasGriefingProtocolPremiumBps_works(
    //         defaultFixedFuzzedFieldsForFastUnitTesting,
    //         secondsBeforeRefinance,
    //         updatedGasGriefingProtocolPremiumAmount
    //     );
    // }

    // function _test_cannot_updateGasGriefingProtocolPremiumBps_if_not_owner() private {
    //     uint16 updatedGasGriefingProtocolPremiumAmount = 5000;

    //     vm.startPrank(borrower1);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     lending.updateGasGriefingProtocolPremiumBps(updatedGasGriefingProtocolPremiumAmount);
    //     vm.stopPrank();
    // }

    // function test_unit_cannot_updateGasGriefingProtocolPremiumBps_if_not_owner() public {
    //     _test_cannot_updateGasGriefingProtocolPremiumBps_if_not_owner();
    // }

    // function _test_cannot_updateGasGriefingProtocolPremiumBps_beyond_max_bps() private {
    //     uint16 updatedGasGriefingProtocolPremiumAmount = 10_001;

    //     vm.startPrank(owner);
    //     vm.expectRevert("00002");
    //     lending.updateGasGriefingProtocolPremiumBps(updatedGasGriefingProtocolPremiumAmount);
    //     vm.stopPrank();
    // }

    // function test_unit_cannot_updateGasGriefingProtocolPremiumBps_beyond_max_bps() public {
    //     _test_cannot_updateGasGriefingProtocolPremiumBps_beyond_max_bps();
    // }
}
