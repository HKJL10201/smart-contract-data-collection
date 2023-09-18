// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IProxy {
    /**
     * @notice Administrator for this contract
     */
    function admin() external returns (address);

    /**
     * @notice Accepts new implementation of AccountFactory. msg.sender must be pendingImplementation
     * @dev Admin function for new implementation to accept it's role as implementation
     */
    function _acceptImplementation() external;
}
