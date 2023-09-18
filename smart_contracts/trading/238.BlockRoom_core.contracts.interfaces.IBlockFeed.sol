// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IBlockFeed
 * @author javadyakuza
 * @notice BlockFeed interface
 */

interface IBlockFeed {
    /// @param reducedOutside @dev true if block got verified here and got sold off-chain
    /// in this case we will reduce the revelant verified components in BlockFeed contract
    struct BlockOfParams {
        uint256 blockId;
        uint64 nationalId;
        uint8 component;
        bool reducedOutside;
    }

    /**
     * @param _blockBatch an array of the `BlockOfParams` strcut to update the blockOf mapping.
     * @dev the data that feeds this function is only the changed records.
     * @dev after initialing, this function gets called once per day and update's the changed records.
     * @dev blockId's that are added to the platform wont be updated and staty the same. see the {this.setIsBlocked}
     */
    function setBlockOf(BlockOfParams[] calldata _blockBatch) external;

    /**
     * @notice this function prevents updating a blockId that already exist's in `setBlockOf` function.
     * @param _params a instance of the `BlockOfParams` that contains the updating data.
     */
    function setIsBlocked(BlockOfParams calldata _params) external;

    /**
     * @notice feeder will verify a invidual to be a blocker
     * @param _nationalId the nationalId of the user.
     * @param _blockerAddress ETH_address associated with `nationalId`.
     */
    function setBlockerAddress(
        uint64 _nationalId,
        address _blockerAddress
    ) external;

    /**
     * @param _nationalId the nationalId of the user.
     * @return _blockerAddress returrns the ETH_address associated with `nationalId`.
     */
    function getBlockerAddress(
        uint64 _nationalId
    ) external view returns (address _blockerAddress);

    /**
     * @notice validates that if a blocker actually owns a block
     * @param _blockId blockId
     * @param _nationalId requester's nationalId
     * @param _component components of the blockId
     */
    function getBlockOf(
        uint256 _blockId,
        uint64 _nationalId,
        uint8 _component
    ) external view returns (bool isUsersBlock);

    /**
     * @notice @dev eveery block that gets verified needs to pass a day in seconds in order to be able to be wrapped in BLockWrapper
     * the reason is for preventing user to verify the block in the platform and sell it outside and make a profit by selling in our platform too
     * since every day the block ownerships gets updated this operatin is imposible
     * @param _blockId blockId
     * @param _component components of the blockId
     */
    function isBlockPending(
        uint256 _blockId,
        uint8 _component
    ) external view returns (bool isPending);
}
