// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IBlockers
 * @author javadyakuza
 * @notice Blockers interface
 */

interface IBlockers {
    /**
     * @dev adds a user as a blocker.
     * @param _nationalId blocker antionalId.
     */
    function addBlocker(uint64 _nationalId) external;

    /**
     * @dev gets a address and returns the blocker nationalId which that address is added with.
     * @param _blocker ETH_address of the blocker.
     */
    function _nationalIdOf(
        address _blocker
    ) external view returns (uint64 _nationalId);

    /**
     * @dev returns true if the given EtH_address is added to the BlockRoom and viceversa.
     * @param _blocker ETH_address of the blocker.
     */
    function _isBlocker(
        address _blocker
    ) external view returns (bool _IsBlocker);
}
