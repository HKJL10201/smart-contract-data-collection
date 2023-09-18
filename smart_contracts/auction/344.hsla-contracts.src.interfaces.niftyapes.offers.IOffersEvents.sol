//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IOffersStructs.sol";

/// @title Events emitted by the offers part of the protocol.
interface IOffersEvents {
    /// @notice Emitted when a new offer is stored on chain
    /// @param creator The creator of the offer, this can either be a borrower or a lender (check boolean flag in the offer).
    /// @param nftContractAddress The nft contract address
    /// @param nftId The nft id, this field can be meaningless if the offer is a floor term offer
    /// @param offer The offer details
    /// @param offerHash The offer hash
    event NewOffer(
        address indexed creator,
        address indexed nftContractAddress,
        uint256 indexed nftId,
        IOffersStructs.Offer offer,
        bytes32 offerHash
    );

    /// @notice Emitted when a offer is removed from chain
    /// @param creator The creator of the offer, this can either be a borrower or a lender (check boolean flag in the offer).
    /// @param nftContractAddress The nft contract address
    /// @param nftId The nft id, this field can be meaningless if the offer is a floor term offer
    /// @param offer The offer details
    /// @param offerHash The offer hash
    event OfferRemoved(
        address indexed creator,
        address indexed nftContractAddress,
        uint256 indexed nftId,
        IOffersStructs.Offer offer,
        bytes32 offerHash
    );

    /// @notice Emitted when a offer signature gets has been used
    /// @param nftContractAddress The nft contract address
    /// @param nftId The nft id, this field can be meaningless if the offer is a floor term offer
    /// @param offer The offer details
    /// @param signature The signature that has been revoked
    event OfferSignatureUsed(
        address indexed nftContractAddress,
        uint256 indexed nftId,
        IOffersStructs.Offer offer,
        bytes signature
    );

    /// @notice Emitted when the associated lending contract address is changed
    /// @param oldLendingContractAddress The old lending contract address
    /// @param newLendingContractAddress The new lending contract address
    event OffersXLendingContractAddressUpdated(
        address oldLendingContractAddress,
        address newLendingContractAddress
    );

    /// @notice Emitted when the associated signature lending contract address is changed
    /// @param oldSigLendingContractAddress The old lending contract address
    /// @param newSigLendingContractAddress The new lending contract address
    event OffersXSigLendingContractAddressUpdated(
        address oldSigLendingContractAddress,
        address newSigLendingContractAddress
    );
}
