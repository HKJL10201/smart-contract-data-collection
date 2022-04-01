// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface ISyntheticBotToken {
    // Views

    /**
     * @dev Returns the USD price of the synthetic bot token.
     */
    function getTokenPrice() external view returns (uint256);

    /**
     * @dev Returns the address of the trading bot associated with this token.
     */
    function getTradingBot() external view returns (address);

    /**
     * @dev Given a position ID, returns the position info.
     * @param _positionID ID of the position NFT.
     * @return (uint256, uint256, uint256, uint256, uint256, uint256) total number of tokens in the position, timestamp the position was created, timestamp the rewards will end, timestamp the rewards were last updated, number of rewards per token, number of rewards per second.
     */
    function getPosition(uint256 _positionID) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    /**
     * @dev Returns the latest timestamp to use when calculating available rewards.
     * @param _positionID ID of the position NFT.
     * @return (uint256) The latest timestamp to use for rewards calculations.
     */
    function lastTimeRewardApplicable(uint256 _positionID) external view returns (uint256);

     /**
     * @dev Returns the total amount of rewards remaining for the given position.
     * @param _positionID ID of the position NFT.
     * @return (uint256) Total amount of rewards remaining.
     */
    function remainingRewards(uint256 _positionID) external view returns (uint256);

    /**
     * @dev Returns the user's amount of rewards remaining for the given position.
     * @param _user Address of the user.
     * @param _positionID ID of the position NFT.
     * @return (uint256) User's amount of rewards remaining.
     */
    function remainingRewardsForUser(address _user, uint256 _positionID) external view returns (uint256);

    /**
     * @dev Returns the number of rewards available per token for the given position.
     * @param _positionID ID of the position NFT.
     * @return (uint256) Number of rewards per token.
     */
    function rewardPerToken(uint256 _positionID) external view returns (uint256);

    /**
     * @dev Returns the amount of rewards the user has earned for the given position.
     * @param _account Address of the user.
     * @param _positionID ID of the position NFT.
     * @return (uint256) Amount of rewards earned
     */
    function earned(address _account, uint256 _positionID) external view returns (uint256);

    // Mutative

    /**
     * @dev Mints synthetic bot tokens.
     * @notice Need to approve (botTokenPrice * numberOfTokens * (mintFee + 10000) / 10000) worth of mcUSD before calling this function.
     * @param _numberOfTokens Number of synthetic bot tokens to mint.
     * @param _duration Number of weeks before rewards end.
     */
    function mintTokens(uint256 _numberOfTokens, uint256 _duration) external;

    /**
     * @dev Claims available rewards for the given position.
     * @notice Only the position owner can call this function.
     * @param _positionID ID of the position NFT.
     */
    function claimRewards(uint256 _positionID) external;
}