// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../common/BaseTest.sol";
import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersEvents.sol";

contract TestGetOfferSigner is Test, BaseTest, IOffersEvents, OffersLoansRefinancesFixtures {
    uint256 immutable SIGNER_PRIVATE_KEY_1 =
        0x60b919c82f0b4791a5b7c6a7275970ace1748759ebdaa4076d7eeed9dbcff3c3;
    address immutable SIGNER_1 = 0x503408564C50b43208529faEf9bdf9794c015d52;

    function setUp() public override {
        super.setUp();
    }

    function test_unit_getOfferSigner() public {
        Offer memory offer = Offer({
            creator: lender1,
            nftContractAddress: address(0xB4FFCD625FefD541b77925c7A37A55f488bC69d9),
            interestRatePerSecond: 3,
            fixedTerms: false,
            floorTerm: true,
            lenderOffer: true,
            nftId: 1,
            asset: address(0x18669eb6c7dFc21dCdb787fEb4B3F1eBb3172400),
            amount: 6,
            duration: 1 days,
            expiration: uint32(1657217355),
            floorTermLimit: 1
        });

        bytes32 offerHash = offers.getOfferHash(offer);

        bytes memory signature = sign(SIGNER_PRIVATE_KEY_1, offerHash);

        address signer = offers.getOfferSigner(offer, signature);

        assertEq(signer, SIGNER_1);
    }
}
