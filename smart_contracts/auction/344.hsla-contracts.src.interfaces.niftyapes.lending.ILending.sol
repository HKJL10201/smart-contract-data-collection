//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ILendingAdmin.sol";
import "./ILendingEvents.sol";
import "./ILendingStructs.sol";
import "../offers/IOffersStructs.sol";

/// @title NiftyApes interface for managing loans.
interface ILending is ILendingAdmin, ILendingEvents, ILendingStructs, IOffersStructs {
    /// @notice Returns the address for the associated offers contract
    function offersContractAddress() external view returns (address);

    /// @notice Returns the address for the associated liquidity contract
    function liquidityContractAddress() external view returns (address);

    /// @notice Returns the address for the associated signature lending contract
    function sigLendingContractAddress() external view returns (address);

    /// @notice Returns the fee that computes protocol interest
    ///         This fee is the basis points in order to calculate interest per second
    function protocolInterestBps() external view returns (uint16);

    /// @notice Returns the bps premium for refinancing a loan that the new lender has to pay
    ///         This premium is to compensate lenders for the work of originating a loan
    ///         Fees are denominated in basis points, parts of 10_000
    function originationPremiumBps() external view returns (uint16);

    /// @notice Returns the bps premium for refinancing a loan before the current lender has earned the equivalent amount of interest
    ///         The amount paid decreases as the current lender earns interest
    ///         The maximum amount paid is the value of gasGriefingPremiumBps
    ///         For example, if the value of gasGriefingPremiumBps is 25 and 10 bps of interest has been earned, the premium will be 15 bps paid to the current lender
    ///         Fees are denominated in basis points, parts of 10_000
    function gasGriefingPremiumBps() external view returns (uint16);

    /// @notice Returns the bps premium paid to the protocol for refinancing a loan with terms that do not improve the cumulative terms of the loan by the equivalent basis points
    ///         For example, if termGriefingPremiumBps is 25 then the cumulative improvement of amount, interestRatePerSecond, and duration must be more than 25 bps
    ///         If the amount is 8 bps better, interestRatePerSecond is 7 bps better, and duration is 10 bps better, then no premium is paid
    ///         If any one of those terms is worse then a full premium is paid
    ///         Fees are denominated in basis points, parts of 10_000
    function termGriefingPremiumBps() external view returns (uint16);

    /// @notice Returns the bps premium paid to the protocol for refinancing a loan within 1 hour of default
    ///         Fees are denominated in basis points, parts of 10_000
    function defaultRefinancePremiumBps() external view returns (uint16);

    /// @notice Returns a loan auction identified by a given nft.
    /// @param nftContractAddress The address of the NFT collection
    /// @param nftId The id of a specified NFT
    function getLoanAuction(address nftContractAddress, uint256 nftId)
        external
        view
        returns (LoanAuction memory auction);

    /// @notice Start a loan as the borrower using an offer from the on chain offer book.
    ///         The caller of this method has to be the current owner of the NFT
    /// @param nftContractAddress The address of the NFT collection
    /// @param nftId The id of the specified NFT
    /// @param offerHash The hash of all parameters in an offer
    /// @param floorTerm Indicates whether this is a floor or individual NFT offer.
    function executeLoanByBorrower(
        address nftContractAddress,
        uint256 nftId,
        bytes32 offerHash,
        bool floorTerm
    ) external payable;

    /// @notice Start a loan as the borrower using a signed offer.
    ///         The caller of this method has to be the current owner of the NFT
    ///         Since offers can be floorTerm offers they might not include a specific nft id,
    ///         thus the caller has to pass an extra nft id to the method to identify the nft.
    /// @param offer The details of the loan auction offer
    /// @param signature A signed offerHash
    /// @param nftId The id of a specified NFT
    // function executeLoanByBorrowerSignature(
    //     Offer calldata offer,
    //     bytes memory signature,
    //     uint256 nftId
    // ) external payable;

    /// @notice Start a loan as the lender using an offer from the on chain offer book.
    ///         Borrowers can make offers for loan terms on their NFTs and thus lenders can
    ///         execute these offers
    /// @param nftContractAddress The address of the NFT collection
    /// @param nftId The id of the specified NFT
    /// @param offerHash The hash of all parameters in an offer
    /// @param floorTerm Indicates whether this is a floor or individual NFT offer.
    function executeLoanByLender(
        address nftContractAddress,
        uint256 nftId,
        bytes32 offerHash,
        bool floorTerm
    ) external payable;

    /// @notice Start a loan as the lender using a borrowers offer and signature.
    ///         Borrowers can make offers for loan terms on their NFTs and thus lenders can
    ///         execute these offers
    /// @param offer The details of the loan auction offer
    /// @param signature A signed offerHash
    // function executeLoanByLenderSignature(Offer calldata offer, bytes calldata signature)
    //     external
    //     payable;

    /// @notice Refinance a loan against the on chain offer book as the borrower.
    ///         The new offer has to cover the principle remaining and all lender interest owed on the loan
    ///         Borrowers can refinance at any time even after loan default as long as their NFT collateral has not been seized
    /// @param nftContractAddress The address of the NFT collection
    /// @param nftId The id of the specified NFT
    /// @param floorTerm Indicates whether this is a floor or individual NFT offer.
    /// @param offerHash The hash of all parameters in an offer. This is used as the unique identifier of an offer.
    function refinanceByBorrower(
        address nftContractAddress,
        uint256 nftId,
        bool floorTerm,
        bytes32 offerHash,
        uint32 expectedLastUpdatedTimestamp
    ) external;

    /// @notice Refinance a loan against an off chain signed offer as the borrower.
    ///         The new offer has to cover the principle remaining and all lender interest owed on the loan
    ///         Borrowers can refinance at any time even after loan default as long as their NFT collateral has not been seized
    /// @param offer The details of the loan auction offer
    /// @param signature The signature for the offer
    /// @param nftId The id of a specified NFT
    // function refinanceByBorrowerSignature(
    //     Offer calldata offer,
    //     bytes memory signature,
    //     uint256 nftId
    // ) external;

    /// @notice Refinance a loan against a new offer.
    ///         The new offer must improve terms for the borrower
    ///         Lender must improve terms by a cumulative 25 bps or pay a 25 bps premium
    ///         For example, if termGriefingPremiumBps is 25 then the cumulative improvement of amount, interestRatePerSecond, and duration must be more than 25 bps
    ///         If the amount is 8 bps better, interestRatePerSecond is 7 bps better, and duration is 10 bps better, then no premium is paid
    ///         If any one of those terms is worse then a full premium is paid
    ///         The Lender must allow 25 bps on interest to accrue or pay a gas griefing premium to the current lender
    ///         This premium is equal to gasGriefingPremiumBps - interestEarned
    /// @param offer The details of the loan auction offer
    /// @param expectedLastUpdatedTimestamp The timestamp of the expected terms. This allows lenders to avoid being frontrun and forced to pay a gasGriefingPremium.
    ///        Lenders can provide a 0 value if they are willing to pay the gasGriefingPremium in a high volume loanAuction
    function refinanceByLender(Offer calldata offer, uint32 expectedLastUpdatedTimestamp) external;

    /// @notice Allows borrowers to draw a higher balance on their loan if it has been refinanced with a higher maximum amount
    ///         Drawing down value increases the maximum loan pay back amount and so is not automatically imposed on a refinance by lender, hence this function.
    ///         If a lender does not have liquidity to support a refinanced amount the borrower will draw whatever amount is available,
    ///         the lender's interest earned so far is slashed, and the loan amount is set to the amount currently drawn
    /// @param nftContractAddress The address of the NFT collection
    /// @param nftId The id of the specified NFT
    /// @param drawAmount The amount of value to draw and add to the loan amountDrawn
    function drawLoanAmount(
        address nftContractAddress,
        uint256 nftId,
        uint256 drawAmount
    ) external;

    /// @notice Repay a loan and release the underlying collateral.
    ///         The method automatically computes owed interest.
    /// @param nftContractAddress The address of the NFT collection
    /// @param nftId The id of the specified NFT
    function repayLoan(address nftContractAddress, uint256 nftId) external payable;

    /// @notice Repay someone elses loan
    ///         This function is similar to repayLoan except that it allows for msg.sender to not be
    ///         the borrower of the loan.
    ///         The reason this is broken into another function is to make it harder to accidentally
    ///         be repaying someone elses loan.
    ///         Unless you are intending to repay someone elses loan you should be using #repayLoan instead
    ///         The main use case for this function is to have a bot repay a loan on behalf of a borrower
    /// @param nftContractAddress The address of the NFT collection
    /// @param nftId The id of the specified NFT
    function repayLoanForAccount(
        address nftContractAddress,
        uint256 nftId,
        uint32 expectedLoanBeginTimestamp
    ) external payable;

    /// @notice Repay part of an open loan.
    ///         Repaying part of a loan will lower the remaining interest accumulated
    /// @param nftContractAddress The address of the NFT collection
    /// @param nftId The id of the specified NFT
    /// @param amount The amount of value to pay down on the principle of the loan
    function partialRepayLoan(
        address nftContractAddress,
        uint256 nftId,
        uint256 amount
    ) external payable;

    /// @notice Seizes an asset if the loan has expired and sends it to the lender
    ///         This function can be called by anyone as soon as the loan is expired without having been repaid in full.
    ///         This function allows anyone to call it so that an automated bot may seize the asset on behalf of a lender.
    /// @param nftContractAddress The address of the NFT collection
    /// @param nftId The id of the specified NFT
    function seizeAsset(address nftContractAddress, uint256 nftId) external;

    /// @notice Returns the owner of a given nft if there is a current loan on the NFT, otherwise zero.
    /// @param nftContractAddress The address of the given nft contract
    /// @param nftId The id of the given nft
    function ownerOf(address nftContractAddress, uint256 nftId) external view returns (address);

    /// @notice Returns interest since the last update to the loan
    ///         This only includes the interest from the current active interest period.
    /// @param nftContractAddress The address of the NFT collection
    /// @param nftId The id of the specified NFT
    function calculateInterestAccrued(address nftContractAddress, uint256 nftId)
        external
        view
        returns (uint256, uint256);

    /// @notice Returns the pinterestRatePerSecond for a given set of terms
    /// @param amount The amount of the loan
    /// @param interestBps in basis points
    /// @param duration The duration of the loan
    function calculateInterestPerSecond(
        uint256 amount,
        uint256 interestBps,
        uint256 duration
    ) external pure returns (uint96);

    /// @notice Returns the delta between the required accumulated interest and the current accumulated interest
    /// @param nftContractAddress The address of the NFT collection
    /// @param nftId The id of the specified NFT
    function checkSufficientInterestAccumulated(address nftContractAddress, uint256 nftId)
        external
        view
        returns (uint256);

    /// @notice Returns whether the lender has provided sufficient terms to not be charged a term griefing premium
    ///         Amount and duration must be equal to or greater than, and interestRatePerSecond must be less than
    ///         or equal to the current terms or function will fail
    /// @param nftContractAddress The address of the NFT collection
    /// @param nftId The id of the specified NFT
    /// @param amount The amount of asset offered
    /// @param interestRatePerSecond The interest rate per second offered
    /// @param duration The duration of the loan offered
    function checkSufficientTerms(
        address nftContractAddress,
        uint256 nftId,
        uint128 amount,
        uint96 interestRatePerSecond,
        uint32 duration
    ) external view returns (bool);

    /// @notice Function only callable by the NiftyApesSigLending contract
    ///         Allows SigLending contract to execute loan directly
    /// @param offer The details of the loan auction offer
    /// @param lender The lender of the loan
    /// @param borrower The borrower of the loan
    /// @param nftId The id of the specified NFT
    function doExecuteLoan(
        Offer memory offer,
        address lender,
        address borrower,
        uint256 nftId
    ) external;

    /// @notice Function only callable by the NiftyApesSigLending contract
    ///         Allows SigLending contract to refinance a loan directly
    /// @param offer The details of the loan auction offer
    /// @param nftId The id of the specified NFT
    /// @param nftOwner owner of the nft in the lending.sol lendingAuction
    function doRefinanceByBorrower(
        Offer memory offer,
        uint256 nftId,
        address nftOwner,
        uint32 expectedLastUpdatedTimestamp
    ) external;

    function initialize(
        address newLiquidityContractAddress,
        address newOffersContractAddress,
        address newSigLendingContractAddress
    ) external;
}
