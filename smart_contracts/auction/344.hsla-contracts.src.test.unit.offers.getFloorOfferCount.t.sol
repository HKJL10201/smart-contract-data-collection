// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersEvents.sol";

contract TestGetFloorOfferCount is Test, IOffersEvents, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function test_fuzz_getFloorOfferCount(FuzzedOfferFields memory fuzzed)
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
    }
}
