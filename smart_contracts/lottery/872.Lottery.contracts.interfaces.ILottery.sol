// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILottery {
    struct lottery {
        uint256 index;
        address[] holders;
        address winner;
    }

    /// @notice Update ticket price
    /// @dev Only owner can call this function.
    /// @param newTicketPrice_ New ticket price.
    function modifyTicketPrice(uint256 newTicketPrice_) external;

    /// @notice Update swap percent.
    /// @dev Only owner can call this function.
    /// @param newSwapPercent_ New swap percent.
    function modifySwapPercent(uint256 newSwapPercent_) external;

    /// @notice Update max ticket count users can buy once.
    /// @dev Only owner can call this function.
    /// @param newCnt_ New max count.
    function modifyMaxBuyTicketCnt(uint256 newCnt_) external;

    /// @notice Update threshold ticket count.
    /// @dev Only owner can call this function.
    /// @param newThreshold_ New ticket price.
    function modifyThresholdTicketCnt(uint256 newThreshold_) external;

    /// @notice Get left tickets on current lottery.
    /// @return Return left ticket count.
    function leftTicketCnt() external view returns (uint256);

    /// @notice Get winner address.
    /// @param lotteryId_ The past lottery id.
    /// @return Address of winner.
    function getWinner(uint256 lotteryId_) external view returns (address);

    /// @notice Buy tickets with priceToken.
    /// @dev Users can buy multiple tickets but should be less than max amount.
    /// @param amount_ The amount of tickets.
    function buyTicket(uint256 amount_) external;

    event TicketSale(uint256 saleId, uint256 ticketPrice, uint256 totalTickets);

    event SwappedPriceTokens(uint256 saleId, uint256 swappedAmount);

    event CreatedLottery(uint256 lotteryId);

    event WinnerForLottery(address indexed winner, uint256 lotteryId);

    event CreateTicketNFT(address indexed ticketNFTAddr);

    event CreateRewardNFT(address indexed rewardNFTAddr);
}