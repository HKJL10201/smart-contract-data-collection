//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IOffersStructs {
    //timestamps are uint32, will expire in 2048
    struct Offer {
        // SLOT 0 START
        // Offer creator
        address creator;
        // offer loan duration
        uint32 duration;
        // The expiration timestamp of the offer in a unix timestamp in seconds
        uint32 expiration;
        // is loan offer fixed terms or open for perpetual auction
        bool fixedTerms;
        // is offer for single NFT or for every NFT in a collection
        bool floorTerm;
        // Whether or not this offer was made by a lender or a borrower
        bool lenderOffer;
        // SLOT 1 START
        // offer NFT contract address
        address nftContractAddress;
        // SLOT 2 START
        // offer NFT ID
        uint256 nftId; // ignored if floorTerm is true
        // SLOT 3 START
        // offer asset type
        address asset;
        // SLOT 4 START
        // offer loan amount
        uint128 amount;
        // offer interest rate per second. (Amount * InterestRate) / MAX-BPS / Duration
        uint96 interestRatePerSecond;
        // SLOT 5 START
        // floor offer usage limit, ignored if floorTerm is false
        uint64 floorTermLimit;
    }
}
