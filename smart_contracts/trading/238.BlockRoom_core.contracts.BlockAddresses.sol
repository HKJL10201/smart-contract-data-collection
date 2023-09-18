// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title BlockAddresses
 * @author javadyakuza
 * @notice used to save BlockWrapper and BlockTradin addresses to simplify the the deploying of the contracts procces
 */
contract BlockAddresses {
    address public BlockWrapper;
    address public BlockTrading;

    function setBlockWrapper(address _tempBlockWrapper) external {
        require(BlockWrapper == address(0), "already setted !!");
        BlockWrapper = _tempBlockWrapper;
    }

    function setBlockTrading(address _tempBlockTrading) external {
        require(BlockTrading == address(0), "already setted !!");
        BlockTrading = _tempBlockTrading;
    }

    function modifierIsBlockWrapper(
        address _pretender
    ) external view returns (bool _isBlockWrapper) {
        return _pretender == BlockWrapper;
    }

    function modifierIsBlockTrading(
        address _pretender
    ) external view returns (bool _isBlockTrading) {
        return _pretender == BlockTrading;
    }
}
