// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IExecutionPrice {

    struct Order {
        address user;
        uint256 quantity;
        uint256 amountFilled;
    }

    struct Params {
        uint256 price; // Number of TGEN per bond token.
        uint256 maximumNumberOfInvestors;
        uint256 tradingFee;
        uint256 minimumOrderSize;
        address owner;
    }

    /**
     * @notice Creates an order to buy bond tokens.
     * @dev Executes existing 'sell' orders before adding this order.
     * @param _amount number of bond tokens to buy.
     */
    function buy(uint256 _amount) external;

    /**
     * @notice Creates an order to sell bond tokens.
     * @dev Executes existing 'buy' orders before adding this order.
     * @param _amount number of bond tokens to sell.
     */
    function sell(uint256 _amount) external;

    /**
     * @notice Updates the order quantity and transaction type (buy vs. sell).
     * @dev If the transaction type is different from the original type,
     *          existing orders will be executed before updating this order.
     * @param _amount number of bond tokens to buy/sell.
     * @param _buy whether this is a 'buy' order.
     */
    function updateOrder(uint256 _amount, bool _buy) external;

    /**
     * @notice Updates the trading fee for this ExecutionPrice.
     * @dev This function is meant to be called by the contract owner.
     * @param _newFee the new trading fee.
     */
    function updateTradingFee(uint256 _newFee) external;

    /**
     * @notice Updates the minimum order size for this ExecutionPrice.
     * @dev This function is meant to be called by the contract owner.
     * @param _newSize the new minimum order size.
     */
    function updateMinimumOrderSize(uint256 _newSize) external;

    /**
     * @notice Initializes the contract's parameters.
     * @dev This function is meant to be called by the PriceManager contract when creating this contract.
     * @param _price the price of each bond token.
     * @param _maximumNumberOfInvestors the maximum number of open orders the queue can have.
     * @param _tradingFee fee that is paid to the contract owner whenever an order is filled; denominated by 10000.
     * @param _minimumOrderSize minimum number of bond tokens per order.
     * @param _owner address of the contract owner.
     */
    function initialize(uint256 _price, uint256 _maximumNumberOfInvestors, uint256 _tradingFee, uint256 _minimumOrderSize, address _owner) external;

    /**
     * @notice Updates the owner of this ExecutionPrice.
     * @dev This function is meant to be called by the PriceManager contract whenever the
     *          ExecutionPrice NFT is purchased by another user.
     * @param _newOwner the new contract owner.
     */
    function updateContractOwner(address _newOwner) external;
}