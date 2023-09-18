// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBlock.sol";
import "./interfaces/IBlockers.sol";
import "./interfaces/IBlockFeed.sol";
import "./interfaces/IBlockStorage.sol";
import "./interfaces/IBlockAddresses.sol";
import "./helpers/zeroAddressPreventer.sol";

/**
 * @title BlockWrapper
 * @author javadyakuza
 * @notice this contract is used to wrap the house into blocks
 */
contract BlockWrapper is Ownable, ZAP {
    IBlock public immutable BLOCK;
    IBlockers public immutable BLOCKERS;
    IBlockFeed public immutable BLOCKFEED;
    IBlockStorage public immutable BLOCKSTORAGE;
    IBlockAddresses public immutable Addresses;

    constructor(
        IBlock tempIBlock,
        IBlockers tempIBlockers,
        IBlockFeed tempIBlockFeed,
        IBlockStorage tempIBlockStorage,
        IBlockAddresses tempIAddresses
    )
        nonZeroAddress(address(tempIBlock))
        nonZeroAddress(address(tempIBlockers))
        nonZeroAddress(address(tempIBlockFeed))
        nonZeroAddress(address(tempIBlockStorage))
        nonZeroAddress(address(tempIAddresses))
    {
        BLOCK = tempIBlock;
        BLOCKERS = tempIBlockers;
        BLOCKFEED = tempIBlockFeed;
        BLOCKSTORAGE = tempIBlockStorage;
        Addresses = tempIAddresses;
        // updating the Addresses contract addresses
        Addresses.setBlockWrapper(address(this));
    }

    modifier IsBlocker() {
        require(BLOCKERS._isBlocker(msg.sender), "user must be blocker !!");
        _;
    }

    // once a block is wrapped it can not be traded outside of this platform
    function blockWrapper(
        uint256 _blockId,
        uint8 _component
    ) external IsBlocker {
        // checking the ownership of requested blockId
        uint64 tempNationalId = BLOCKERS._nationalIdOf(msg.sender);
        require(
            BLOCKFEED.getBlockOf(_blockId, tempNationalId, _component),
            "only Block owner can wrap it !!"
        );
        // checking that if the required time has been passed (1day) to wrap the block
        /// @dev uncomment incase of prodiction usage
        // require(
        //     !BLOCKFEED.isBlockPending(_blockId, _component),
        //     "your block is pending !!"
        // );
        //updating the oracle
        BLOCKFEED.setIsBlocked(
            IBlockFeed.BlockOfParams(
                _blockId,
                tempNationalId,
                BLOCKSTORAGE.getBlockOwner(_blockId, msg.sender), // BlockFeed and BLOCKSTORAGE syncing
                false
            )
        );
        // adding the block to the storage
        BLOCKSTORAGE.transferBlock(
            address(0),
            msg.sender,
            _blockId,
            _component
        );
        //minting BLOCK for blocker
        BLOCK.mintBlock(msg.sender, _blockId, _component, "");
    }
}
