// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IBlockStorage
 * @author javadyakuza
 * @notice BlockStorage interface
 */

interface IBlockStorage {
    struct BlockInfo {
        uint256 blockId; /// @param blockId blockId.
        uint8 component; /// @param component component.
    }

    /**
     *
     * @param _fromBlocker ETH_address of the sender blocker.
     * @param _toBlocker ETH_address of the receiver blocker.
     * @param _blockId blockId.
     * @param _component component.
     * @dev this function first add the blockId to the receiver blocker and then removes it from the sender blocker.
     * // many possibilities are covered in this function to prevent any 🐛 in the functionality of the smart contract.
     */
    function transferBlock(
        address _fromBlocker, // address(0) if the wrapper contract is calling
        address _toBlocker,
        uint256 _blockId,
        uint8 _component
    ) external;

    /**
     *
     * @param _blocker ETH_address of the blocker.
     * @return _blockersBlocks function returns an array of the `BlockInfo` struct.
     */
    function getBlockersBlocks(
        address _blocker
    ) external view returns (BlockInfo[] memory _blockersBlocks);

    /**
     *
     * @param _blockId blockId.
     * @param _blocker ETH_address of the blocker.
     * @return _component this function returns the component's owned from a specific block by the `_blocker`.
     */
    function getBlockOwner(
        uint256 _blockId,
        address _blocker
    ) external view returns (uint8 _component);
}
