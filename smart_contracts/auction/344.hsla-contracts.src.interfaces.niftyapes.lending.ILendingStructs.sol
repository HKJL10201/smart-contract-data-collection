//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ILendingStructs {
    //timestamps are uint32, will expire in 2048
    struct LoanAuction {
        // SLOT 0 START
        // The original owner of the nft.
        // If there is an active loan on an nft, nifty apes contracts become the holder (original owner)
        // of the underlying nft. This field tracks who to return the nft to if the loan gets repaid.
        address nftOwner;
        // end timestamp of loan
        uint32 loanEndTimestamp;
        /// Last timestamp this loan was updated
        uint32 lastUpdatedTimestamp;
        // Whether or not the loan can be refinanced
        bool fixedTerms;
        // The current lender of a loan
        address lender;
        // interest rate of loan in basis points
        uint96 interestRatePerSecond;
        // SLOT 1 START
        // the asset in which the loan has been denominated
        address asset;
        // beginning timestamp of loan
        uint32 loanBeginTimestamp;
        // refinanceByLender was last action, enables slashing
        bool lenderRefi;
        // cumulative interest of varying rates paid by new lenders to buy out the loan auction
        uint128 accumulatedLenderInterest;
        // 32 unused bytes in slot 1
        // SLOT 2 START
        // cumulative interest of varying rates accrued by the protocol. Paid by lenders upon refinance, repaid by borrower at the end of the loan.
        uint128 accumulatedPaidProtocolInterest;
        // The maximum amount of tokens that can be drawn from this loan
        uint128 amount;
        // SLOT 3 START
        // amount withdrawn by the nftOwner. This is the amount they will pay interest on, with this value as minimum
        uint128 amountDrawn;
        // This fee is the rate of interest per second for the protocol
        uint96 protocolInterestRatePerSecond;
        // 32 unused bytes in slot 3
        // SLOT 4 START
        uint128 slashableLenderInterest;
        // cumulative unpaid protocol interest. Accrues per lender period of interest.
        uint128 unpaidProtocolInterest;
    }
}
