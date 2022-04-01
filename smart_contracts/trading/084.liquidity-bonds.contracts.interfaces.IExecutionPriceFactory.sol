// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IExecutionPriceFactory {
    /**
    * @dev Updates the owner of the given ExecutionPrice contract.
    * @notice This function can only be called by the PriceManager contract.
    * @param _executionPrice Address of the ExecutionPrice address.
    * @param _newOwner Address of the new owner for the ExecutionPrice contract.
    */
    function updateContractOwner(address _executionPrice, address _newOwner) external;
}