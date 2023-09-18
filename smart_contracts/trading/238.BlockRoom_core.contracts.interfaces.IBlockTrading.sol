// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IBlockTrading
 * @author javadyakuza
 * @notice BlockTrading interface
 */

interface IBlockTrading {
    struct BlockSaleInfo {
        uint8 component; /// @param component components of the owned blockId by an blocker
        bool saleStatus; /// @param saleStatus true or false, is open to sale or no ?
        uint256 price; /// @param price the price setted for the certained components of the blockId
        IERC20 acceptingToken; /// @param  acceptingToken which token you want to receive for your block
    }

    /**
     *
     * @param _blockId blockId
     * @param _component components
     * @param _price wholePrie for the blockId with certained component
     * @param _Token ERC20 token to receive in exchange of the block ownership
     * @dev this function sets `blocksForSale` mapping for the specific blockId and its information
     */
    function openSalesAndPriceTheBlock(
        uint256 _blockId,
        uint8 _component,
        uint256 _price, // must be in decimals
        IERC20 _Token
    ) external;

    /**
     *@param _blocker the ETH_addres of the blocker
     * @param _blockId blockId
     * @param _component component
     * @dev turns the sale status to false
     */
    function closeBlockSales(
        address _blocker,
        uint256 _blockId,
        uint8 _component
    ) external;

    /**
     *
     * @param _blockId blockId
     * @param _sellerBlocker ETH_address of the seller blocker
     * @param _PaymentToken ERC20 token to pay in exchange of the ownership of the blockId
     * @dev transfers the ownership and the block price.
     */
    function buyBlock(
        uint256 _blockId,
        address _sellerBlocker,
        IERC20 _PaymentToken
    ) external;

    /**
     *
     * @param _blockId blockId
     * @param _blocker ETH_address of the blocker who has setted the blokcId for sale
     * @return _BlockSaleInfo an intance of the `BlockSaleInfo`struct with its assiciated inforamtiion
     *      */
    function getBlocksForSale(
        uint256 _blockId,
        address _blocker
    ) external view returns (BlockSaleInfo memory _BlockSaleInfo);
}
