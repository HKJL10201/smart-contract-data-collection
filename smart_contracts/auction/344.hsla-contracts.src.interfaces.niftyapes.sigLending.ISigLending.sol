//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ISigLendingAdmin.sol";
import "./ISigLendingEvents.sol";
import "../offers/IOffersStructs.sol";

/// @title The signature lending interface for Nifty Apes
///        This interface is intended to be used for interacting with loans on the protocol.
interface ISigLending is ISigLendingAdmin, ISigLendingEvents, IOffersStructs {
    /// @notice Returns the address for the associated offers contract
    function offersContractAddress() external view returns (address);

    /// @notice Returns the address for the associated liquidity contract
    function lendingContractAddress() external view returns (address);

    /// @notice Start a loan as the borrower using a signed offer.
    ///         The caller of this method has to be the current owner of the NFT
    ///         Since offers can be floorTerm offers they might not include a specific nft id,
    ///         thus the caller has to pass an extra nft id to the method to identify the nft.
    /// @param offer The details of the loan auction offer
    /// @param signature A signed offerHash
    /// @param nftId The id of a specified NFT
    function executeLoanByBorrowerSignature(
        Offer calldata offer,
        bytes memory signature,
        uint256 nftId
    ) external payable;

    /// @notice Start a loan as the lender using a borrowers offer and signature.
    ///         Borrowers can make offers for loan terms on their NFTs and thus lenders can
    ///         execute these offers
    /// @param offer The details of the loan auction offer
    /// @param signature A signed offerHash
    function executeLoanByLenderSignature(Offer calldata offer, bytes calldata signature)
        external
        payable;

    /// @notice Refinance a loan against an off chain signed offer as the borrower.
    ///         The new offer has to cover the principle remaining and all lender interest owed on the loan
    ///         Borrowers can refinance at any time even after loan default as long as their NFT collateral has not been seized
    /// @param offer The details of the loan auction offer
    /// @param signature The signature for the offer
    /// @param nftId The id of a specified NFT
    function refinanceByBorrowerSignature(
        Offer calldata offer,
        bytes memory signature,
        uint256 nftId,
        uint32 expectedLastUpdatedTimestamp
    ) external;

    function initialize(address newOffersContractAddress) external;
}
