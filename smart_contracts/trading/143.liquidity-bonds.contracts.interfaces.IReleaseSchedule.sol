// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IReleaseSchedule {
    /**
     * @notice Returns the timestamp at which rewards will start.
     */
    function distributionStartTime() external view returns (uint256);

    /**
     * @notice Returns the total number of tokens that will be released in the given cycle.
     * @param _cycleIndex index of the cycle to check.
     * @return (uint256) total number of tokens released during the given cycle.
     */
    function getTokensForCycle(uint256 _cycleIndex) external view returns (uint256);

    /**
     * @notice Returns the index of the current cycle.
     * @return (uint256) index of the current cycle.
     */
    function getCurrentCycle() external view returns (uint256);

    /**
     * @notice Returns the duration of each cycle.
     * @return (uint256) duration of each cycle (in seconds).
     */
    function cycleDuration() external view returns (uint256);

    /**
     * @notice Returns the starting timestamp of the given cycle.
     * @param _cycleIndex index of the cycle to check.
     * @return (uint256) starting timestamp of the cycle.
     */
    function getStartOfCycle(uint256 _cycleIndex) external view returns (uint256);

    /**
     * @notice Given the index of a cycle, returns the number of tokens unlocked per second during the cycle.
     * @param _cycleIndex index of the cycle to check.
     * @return (uint256) number of tokens per second.
     */
    function getRewardRate(uint256 _cycleIndex) external view returns (uint256);

    /**
     * @notice Returns the number of tokens unlocked per second in the current cycle.
     * @return (uint256) number of tokens per second.
     */
    function getCurrentRewardRate() external view returns (uint256);

    /**
     * @notice Returns the starting timestamp of the currenet cycle.
     * @return (uint256) starting timestamp.
     */
    function getStartOfCurrentCycle() external view returns (uint256);
}
