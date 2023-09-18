//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/niftyapes/lending/ILending.sol";
import "./interfaces/niftyapes/sigLending/ISigLending.sol";
import "./interfaces/niftyapes/offers/IOffers.sol";

/// @title NiftyApes Signature Lending
/// @custom:version 1.0
/// @author captnseagraves (captnseagraves.eth)
/// @custom:contributor dankurka
/// @custom:contributor 0xAlcibiades (alcibiades.eth)
/// @custom:contributor zjmiller (zjmiller.eth)

contract NiftyApesSigLending is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ISigLending
{
    /// @inheritdoc ISigLending
    address public offersContractAddress;

    /// @inheritdoc ISigLending
    address public lendingContractAddress;

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting storage.
    uint256[500] private __gap;

    /// @notice The initializer for the NiftyApes protocol.
    ///         Nifty Apes is intended to be deployed behind a proxy amd thus needs to initialize
    ///         its state outsize of a constructor.
    function initialize(address newOffersContractAddress) public initializer {
        offersContractAddress = newOffersContractAddress;

        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    }

    /// @inheritdoc ISigLendingAdmin
    function updateLendingContractAddress(address newLendingContractAddress) external onlyOwner {
        emit SigLendingXLendingContractAddressUpdated(
            lendingContractAddress,
            newLendingContractAddress
        );
        lendingContractAddress = newLendingContractAddress;
    }

    /// @inheritdoc ISigLendingAdmin
    function pause() external onlyOwner {
        _pause();
    }

    /// @inheritdoc ISigLendingAdmin
    function unpause() external onlyOwner {
        _unpause();
    }

    function _sigOfferNftIdAndCountChecks(
        Offer memory offer,
        bytes memory signature,
        uint256 nftId
    ) internal returns (address signer) {
        signer = IOffers(offersContractAddress).getOfferSigner(offer, signature);

        _requireOfferCreator(offer, signer);
        IOffers(offersContractAddress).requireAvailableSignature(signature);
        IOffers(offersContractAddress).requireSignature65(signature);
        IOffers(offersContractAddress).requireMinimumDuration(offer);

        if (!offer.floorTerm) {
            _requireMatchingNftId(offer, nftId);
            IOffers(offersContractAddress).markSignatureUsed(offer, signature);
        } else {
            require(
                IOffers(offersContractAddress).getSigFloorOfferCount(signature) <
                    offer.floorTermLimit,
                "00051"
            );

            IOffers(offersContractAddress).incrementSigFloorOfferCount(signature);
        }
    }

    // @inheritdoc ISigLending
    function executeLoanByBorrowerSignature(
        Offer memory offer,
        bytes memory signature,
        uint256 nftId
    ) external payable whenNotPaused nonReentrant {
        address lender = _sigOfferNftIdAndCountChecks(offer, signature, nftId);

        _requireLenderOffer(offer);

        // execute state changes for executeLoanByBid
        ILending(lendingContractAddress).doExecuteLoan(offer, lender, msg.sender, nftId);
    }

    // @inheritdoc ISigLending
    function executeLoanByLenderSignature(Offer memory offer, bytes memory signature)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        address borrower = IOffers(offersContractAddress).getOfferSigner(offer, signature);

        _requireOfferCreator(offer, borrower);
        IOffers(offersContractAddress).requireAvailableSignature(signature);
        IOffers(offersContractAddress).requireSignature65(signature);
        IOffers(offersContractAddress).requireMinimumDuration(offer);
        _requireBorrowerOffer(offer);
        IOffers(offersContractAddress).requireNoFloorTerms(offer);

        IOffers(offersContractAddress).markSignatureUsed(offer, signature);

        ILending(lendingContractAddress).doExecuteLoan(offer, msg.sender, borrower, offer.nftId);
    }

    // @inheritdoc ISigLending
    function refinanceByBorrowerSignature(
        Offer memory offer,
        bytes memory signature,
        uint256 nftId,
        uint32 expectedLastUpdatedTimestamp
    ) external whenNotPaused nonReentrant {
        _sigOfferNftIdAndCountChecks(offer, signature, nftId);

        ILending(lendingContractAddress).doRefinanceByBorrower(
            offer,
            nftId,
            msg.sender,
            expectedLastUpdatedTimestamp
        );
    }

    function _requireLenderOffer(Offer memory offer) internal pure {
        require(offer.lenderOffer, "00012");
    }

    function _requireBorrowerOffer(Offer memory offer) internal pure {
        require(!offer.lenderOffer, "00013");
    }

    function _requireMatchingNftId(Offer memory offer, uint256 nftId) internal pure {
        require(nftId == offer.nftId, "00022");
    }

    function _requireOfferCreator(Offer memory offer, address creator) internal pure {
        require(creator == offer.creator, "00024");
    }

    // solhint-disable-next-line no-empty-blocks
    function renounceOwnership() public override onlyOwner {}
}
