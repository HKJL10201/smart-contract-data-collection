//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ILendingStructs.sol";

/// @title Events emitted by the lending part of the protocol.
interface ILendingEvents {
    /// @notice Emitted when a new loan is executed
    /// @param nftContractAddress The nft contract address
    /// @param nftId The nft id
    /// @param loanAuction The loanAuction details
    event LoanExecuted(
        address indexed nftContractAddress,
        uint256 indexed nftId,
        ILendingStructs.LoanAuction loanAuction
    );

    /// @notice Emitted when a loan is refinanced
    /// @param nftContractAddress The nft contract address
    /// @param nftId The nft id
    /// @param loanAuction The loanAuction details
    event Refinance(
        address indexed nftContractAddress,
        uint256 indexed nftId,
        ILendingStructs.LoanAuction loanAuction
    );

    /// @notice Emitted when a loan amount is drawn
    /// @param nftContractAddress The nft contract address
    /// @param nftId The nft id
    /// @param drawAmount The added amount drawn
    /// @param loanAuction The loanAuction details
    event AmountDrawn(
        address indexed nftContractAddress,
        uint256 indexed nftId,
        uint256 drawAmount,
        ILendingStructs.LoanAuction loanAuction
    );

    /// @notice Emitted when a loan is repaid
    /// @param nftContractAddress The nft contract address
    /// @param nftId The nft id
    ///  @param totalPayment The total payment amount
    /// @param loanAuction The loanAuction details
    event LoanRepaid(
        address indexed nftContractAddress,
        uint256 indexed nftId,
        uint256 totalPayment,
        ILendingStructs.LoanAuction loanAuction
    );

    /// @notice Emitted when a loan is partially repaid
    /// @param nftContractAddress The nft contract address
    /// @param nftId The nft id
    ///  @param amount The payment amount
    /// @param loanAuction The loanAuction details
    event PartialRepayment(
        address indexed nftContractAddress,
        uint256 indexed nftId,
        uint256 amount,
        ILendingStructs.LoanAuction loanAuction
    );

    /// @notice Emitted when an asset is seized
    /// @param nftContractAddress The nft contract address
    /// @param nftId The nft id,
    /// @param loanAuction The loanAuction details
    event AssetSeized(
        address indexed nftContractAddress,
        uint256 indexed nftId,
        ILendingStructs.LoanAuction loanAuction
    );

    /// @notice Emitted when the protocol interest fee is updated.
    ///         Interest is charged per second on a loan.
    ///         This is the fee that the protocol charges for facilitating the loan
    /// @param oldProtocolInterestBps The old value denominated in tokens per second
    /// @param newProtocolInterestBps The new value denominated in tokens per second
    event ProtocolInterestBpsUpdated(uint96 oldProtocolInterestBps, uint96 newProtocolInterestBps);

    /// @notice Emitted when the the bps premium for refinancing a loan that the new lender has to pay is changed
    /// @param oldOriginationPremiumBps The old basis points denominated in parts of 10_000
    /// @param newOriginationPremiumBps The new basis points denominated in parts of 10_000
    event OriginationPremiumBpsUpdated(
        uint16 oldOriginationPremiumBps,
        uint16 newOriginationPremiumBps
    );

    /// @notice Emitted when the bps premium for refinancing a loan before the current lender has earned the equivalent amount of interest has changed
    /// @param oldGasGriefingPremiumBps The old basis points denominated in parts of 10_000
    /// @param newGasGriefingPremiumBps The new basis points denominated in parts of 10_000
    event GasGriefingPremiumBpsUpdated(
        uint16 oldGasGriefingPremiumBps,
        uint16 newGasGriefingPremiumBps
    );

    /// @notice Emitted when the bps premium paid to the protocol for refinancing a loan before the current lender has earned the equivalent amount of interest is changed
    /// @param oldGasGriefingProtocolPremiumBps The old basis points denominated in parts of 10_000
    /// @param newGasGriefingProtocolPremiumBps The new basis points denominated in parts of 10_000
    event GasGriefingProtocolPremiumBpsUpdated(
        uint16 oldGasGriefingProtocolPremiumBps,
        uint16 newGasGriefingProtocolPremiumBps
    );

    /// @notice Emitted when the bps premium paid to the protocol for refinancing a loan with terms that do not improve the cumulative terms of the loan by the equivalent basis points is changed
    /// @param oldTermGriefingPremiumBps The old basis points denominated in parts of 10_000
    /// @param newTermGriefingPremiumBps The new basis points denominated in parts of 10_000
    event TermGriefingPremiumBpsUpdated(
        uint16 oldTermGriefingPremiumBps,
        uint16 newTermGriefingPremiumBps
    );

    /// @notice Emitted when the bps premium paid to the protocol for refinancing a loan within 1 hour of default is changed
    /// @param oldDefaultRefinancePremiumBps The old basis points denominated in parts of 10_000
    /// @param newDefaultRefinancePremiumBps The new basis points denominated in parts of 10_000
    event DefaultRefinancePremiumBpsUpdated(
        uint16 oldDefaultRefinancePremiumBps,
        uint16 newDefaultRefinancePremiumBps
    );

    /// @notice Emitted when sanctions checks are paused
    event LendingSanctionsPaused();

    /// @notice Emitted when sanctions checks are unpaused
    event LendingSanctionsUnpaused();
}
