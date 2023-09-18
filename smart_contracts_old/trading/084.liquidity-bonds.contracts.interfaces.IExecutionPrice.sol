// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IExecutionPrice {
    // Mutative

    /**
     * @dev Creates an order to buy bond tokens.
     * @notice Executes existing 'sell' orders before adding this order.
     * @param _amount number of bond tokens to buy.
     */
    function buy(uint256 _amount) external;

    /**
     * @dev Creates an order to sell bond tokens.
     * @notice Executes existing 'buy' orders before adding this order.
     * @param _amount number of bond tokens to sell.
     */
    function sell(uint256 _amount) external;

    /**
     * @dev Updates the order quantity and transaction type (buy vs. sell).
     * @notice If the transaction type is different from the original type,
     *          existing orders will be executed before updating this order.
     * @param _amount number of bond tokens to buy/sell.
     * @param _buy whether this is a 'buy' order.
     */
    function updateOrder(uint256 _amount, bool _buy) external;

    /**
     * @dev Updates the trading fee for this ExecutionPrice.
     * @notice This function is meant to be called by the contract owner.
     * @param _newFee the new trading fee.
     */
    function updateTradingFee(uint256 _newFee) external;

    /**
     * @dev Updates the minimum order size for this ExecutionPrice.
     * @notice This function is meant to be called by the contract owner.
     * @param _newSize the new minimum order size.
     */
    function updateMinimumOrderSize(uint256 _newSize) external;

    /**
     * @dev Initializes the contract's parameters.
     * @notice This function is meant to be called by the PriceManager contract when creating this contract.
     * @param _price the price of each bond token.
     * @param _maximumNumberOfInvestors the maximum number of open orders the queue can have.
     * @param _tradingFee fee that is paid to the contract owner whenever an order is filled; denominated by 10000.
     * @param _minimumOrderSize minimum number of bond tokens per order.
     * @param _owner address of the contract owner.
     */
    function initialize(uint256 _price, uint256 _maximumNumberOfInvestors, uint256 _tradingFee, uint256 _minimumOrderSize, address _owner) external;

    /**
     * @dev Updates the owner of this ExecutionPrice.
     * @notice This function is meant to be called by the PriceManager contract whenever the
     *          ExecutionPrice NFT is purchased by another user.
     * @param _newOwner the new contract owner.
     */
    function updateContractOwner(address _newOwner) external;
}