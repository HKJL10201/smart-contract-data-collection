// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IBlockAddresses.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./helpers/zeroAddressPreventer.sol";

/**
 * @title BlockStorage
 * @author javadyakuza
 * @notice this contract is used to store the inforamtion about the blocks in BlockRoom
 */
contract BlockStorage is Ownable, ZAP {
    /// @dev emited when a block is transfered within this contract
    event BlockTransfered(
        address indexed _fromBlocker,
        address indexed _toBlocker,
        uint256 _blockId,
        uint8 component
    );

    IBlockAddresses public immutable Addresses;

    mapping(address => BlockInfo[]) public blockerBlocks; //[blockerAddress][[blockId, component]]
    mapping(address => mapping(uint256 => uint256))
        public blockersBlocksIndexes; // after removing a item from an user blocks its index must be cleared
    mapping(uint256 => mapping(address => uint8)) public blockOwner;

    struct BlockInfo {
        uint256 blockId;
        uint8 component;
    }

    constructor(
        IBlockAddresses tempIAddresses
    ) nonZeroAddress(address(tempIAddresses)) {
        Addresses = tempIAddresses;
    }

    modifier isWrapperOrTrader(address _FromBlocker) {
        require(
            Addresses.modifierIsBlockWrapper(msg.sender) ||
                Addresses.modifierIsBlockTrading(msg.sender),
            "only blockWrapper or blockTrading contract allowed to make changes !!"
        );
        if (Addresses.modifierIsBlockTrading(msg.sender)) {
            require(
                _FromBlocker != address(0),
                "BlockTrading can not transfer block from zero-address !!"
            );
        }
        _;
    }

    function updateBlockOwner(
        uint256 _blockId,
        address _blocker,
        uint8 _component
    ) private {
        blockOwner[_blockId][_blocker] = _component;
    }

    function transferBlock(
        address _fromBlocker, // address(0) if the wrapper contract is calling
        address _toBlocker,
        uint256 _blockId,
        uint8 _component
    ) external isWrapperOrTrader(_fromBlocker) nonZeroAddress(_toBlocker) {
        //-- adding the block to the `_toBlocker` --\\

        // merging the blocks if the user already has a share of that component
        // in this case the trading contract is calling this function
        if (blockOwner[_blockId][_toBlocker] != 0) {
            // adding th existing comopnent to the newly
            blockerBlocks[_toBlocker][
                blockersBlocksIndexes[_toBlocker][_blockId]
            ].component += uint8(_component);
            // updating the blockOwner to the latest shares achived by `toBlocker`
            updateBlockOwner(
                _blockId,
                _toBlocker,
                blockerBlocks[_toBlocker][
                    blockersBlocksIndexes[_toBlocker][_blockId]
                ].component
            );
        } else {
            // in this case wrapper or trading contract maybe calling this function
            // adding the block to the blockerBlocks
            blockerBlocks[_toBlocker].push(
                BlockInfo(_blockId, uint8(_component))
            );
            // updating the index of the block
            blockersBlocksIndexes[_toBlocker][_blockId] =
                blockerBlocks[_toBlocker].length -
                1;
            // updating the blockOwner to the latest shares achieved by `toBlocker`
            updateBlockOwner(_blockId, _toBlocker, _component);
        }
        // if zero => wrapper contract calling and viceversa
        if (_fromBlocker != address(0)) {
            // checking if the whole components are being transfered or parrt of it
            if (
                _component ==
                blockerBlocks[_fromBlocker][
                    blockersBlocksIndexes[_fromBlocker][_blockId]
                ].component
            ) {
                //-- removing the block from the `_fromBlocker` --\\
                // means the whole components are being transfered
                // saving the index
                uint256 index = blockersBlocksIndexes[_fromBlocker][_blockId];
                // deleting the index's item
                delete blockerBlocks[_fromBlocker][index];
                // filling the deleted index with the last element
                blockerBlocks[_fromBlocker][index] = blockerBlocks[
                    _fromBlocker
                ][blockerBlocks[_fromBlocker].length - 1];
                // deleting the last element
                blockerBlocks[_fromBlocker].pop();
                // updating the new index's value index in terms of more Blocks than one
                if (blockerBlocks[_fromBlocker].length >= 1) {
                    blockersBlocksIndexes[_fromBlocker][
                        blockerBlocks[_fromBlocker][index].blockId
                    ] = index;
                }
                // removing the deleted item index from `blockersBlocksIndexes`
                delete blockersBlocksIndexes[_fromBlocker][_blockId];
                updateBlockOwner(_blockId, _fromBlocker, 0);
            } else {
                // inthis case we are not having item transportation
                blockerBlocks[_fromBlocker][
                    blockersBlocksIndexes[_fromBlocker][_blockId]
                ].component -= _component;
                updateBlockOwner(
                    _blockId,
                    _fromBlocker,
                    blockerBlocks[_fromBlocker][
                        blockersBlocksIndexes[_fromBlocker][_blockId]
                    ].component
                );
            }
        }
        emit BlockTransfered(_fromBlocker, _toBlocker, _blockId, _component);
    }

    function getBlockersBlocks(
        address _blocker
    ) external view returns (BlockInfo[] memory _blockersBlocks) {
        return blockerBlocks[_blocker];
    }

    function getBlockOwner(
        uint256 _blockId,
        address _blocker
    ) external view returns (uint8 _component) {
        return blockOwner[_blockId][_blocker];
    }
}
