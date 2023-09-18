// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IBlockWrapper
 * @author javadyakuza
 * @notice BlockWrapper interface
 */

interface IBlockWrapper {
    /**
     * @dev this function wrapes a verified house into block
     * @param _blockId blockId
     * @param _component component
     */
    function blockWrapper(uint256 _blockId, uint8 _component) external;
}
