// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IPriceManager {
    // Views

    /**
     * @dev Calculates the price of an ExecutionPrice NFT, given its index.
     * @param _index index of the ExecutionPrice NFT.
     */
    function calculatePrice(uint256 _index) external view returns (uint256);

    /**
     * @dev Checks whether the given ExecutionPrice is registered in PriceManager.
     * @param _contractAddress address of the ExecutionPrice contract.
     * @return (bool) whether the address is registered.
     */
    function executionPriceExists(address _contractAddress) external view returns (bool);

    // Mutative

    /**
     * @dev Registers the NFT at the given index.
     * @param _index index of the ExecutionPrice NFT.
     * @param _owner Address of the NFT's owner.
     * @param _contractAddress Address of the ExecutionPrice associated with this NFT.
     * @param _price The price at which trades in the ExecutionPrice NFT will execute.
     */
    function register(uint256 _index, address _owner, address _contractAddress, uint256 _price) external;
}