// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IBlockAddresses
 * @author javadyakuza
 * @notice BlockAddresses interface
 */

interface IBlockAddresses {
    /**
     *
     * @param _tempBlockWrapper BlockWrapper contract deployed address
     * @dev will set the BlockAddresses once in deployment
     */
    function setBlockWrapper(address _tempBlockWrapper) external;

    /**
     *
     * @param _tempBlockTrading BlockTrading contract deployed address
     * @dev will set the BlockAddresses once in deployment
     */
    function setBlockTrading(address _tempBlockTrading) external;

    /**
     * @param _pretender address that is pretending that is the BlockWrapperContract
     * @dev returns the BlockWrapper deployde contract addresss
     */
    function modifierIsBlockWrapper(
        address _pretender
    ) external view returns (bool _isBlockWrapper);

    /**
     * @param _pretender address that is pretending that is the BlockTradingContract
     * @dev returns the BlockTrading deployde contract addresss
     */
    function modifierIsBlockTrading(
        address _pretender
    ) external view returns (bool _isBlockTrading);
}
