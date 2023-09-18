// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IBlock.
 * @author javad_yakuza.
 * @notice Block interface
 */

interface IBlock {
    /**
     * @notice this function transfers an BlockId from address to another.
     * @param _account ETH_address of the BlockId receiver.
     * @param _id BlockId.
     * @param _amount the amount of the BlockId that is going to be minted for the "account".
     * @param _data the data to use in before and after transfer functions.
     */
    function mintBlock(
        address _account,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    /**
     * @notice this fucntion will return the balance of th user from specific BlockId
     * @param account ETH_address of the token owner
     * @param id BlockId.
     * @return  BlockId balance
     */
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     *
     * @param from ETH_address of the sender of the BlockId
     * @param to ETH_address of the receiver of the BlockId
     * @param id BlockId
     * @param amount amount of the BlockId
     * @param data the data to use in before and after transfer functions.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @dev See {IERC1155-setApprovedForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);
}
