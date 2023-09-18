// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

interface ITradingPlatform is AutomationCompatibleInterface {
    /**
     * @notice Represents an order created by a user.
     * @param userAddress The address of the user who created the order.
     * @param baseToken The address of the token to be swapped from.
     * @param targetToken The address of the token to be swapped to.
     * @param pairFee The fee percentage applied to the swap pair.
     * @param slippage The maximum acceptable slippage percentage for the swap.
     * @param baseAmount The amount of base tokens to be swapped.
     * @param aimTargetTokenAmount The target amount of target tokens to be obtained from the swap.
     * @param minTargetTokenAmount The minimum acceptable amount of target tokens to be obtained from the swap.
     * @param expiration The expiration timestamp of the order.
     * @param boundOrder The ID of the bound order, if any.
     * @param action The type of the order (DCA, TRAILING, LOSS, or PROFIT).
     * @param data Additional data associated with the order.
     */
    struct Order {
        address userAddress; // The address of the user who created the order.
        address baseToken; // The address of the token to be swapped from.
        address targetToken; // The address of the token to be swapped to.
        uint24 pairFee; // The fee percentage applied to the UniSwap V3 pair.
        uint24 slippage; // The maximum acceptable slippage percentage for the swap.
        uint128 baseAmount; // The amount of base tokens to be swapped.
        uint128 aimTargetTokenAmount; // The target amount of target tokens to be obtained from the swap.
        uint128 minTargetTokenAmount; // The minimum acceptable amount of target tokens to be obtained from the swap.
        uint256 expiration; // The expiration timestamp of the order.
        uint256 boundOrder; // The ID of the bound order, if any.
        Action action; // The type of the order (DCA, TRAILING, LOSS, or PROFIT).
        bytes data; // Additional data associated with the order for different orders types.
    }

    /**
     * @notice Represents the information related to an order in the smart contract.
     * @param id The unique identifier of the order.
     * @param order The order details, including user address, token addresses, amounts, fees, and more.
     * @param additionalInformation Additional information associated with the order,
     * such as the last execution time for DCA or the last execution price for trailing orders.
     * @param resultTokenOut The amount of target tokens obtained from executing the order.
     * @param status The status of the order, indicating whether it is active or not.
     */
    struct OrderInfo {
        uint256 id; // The unique identifier of the order.
        Order order; // The order details, {Order} struct.
        uint256 additionalInformation; //  Additional information associated with the order, such as the last execution time for DCA or the last execution price for trailing orders.
        uint256 resultTokenOut; //  The amount of target tokens obtained from executing the order.
        bool status; // The status of the order, indicating whether it is active or not.
    }

    /**
     * @notice Represents the additional data specific to a trailing order.
     * @param baseAmount The base amount of the order, duplicated for calculation purposes.
     * @param fixingPerStep The amount of the base token to fix on each step of the trailing order.
     * @param step The step in percentages for adjusting the trailing order.
     */
    struct TrailingOrderData {
        uint128 baseAmount; // The base amount of the order, duplicated for calculation purposes.
        uint128 fixingPerStep; // The amount of the base token to fix on each step of the trailing order.
        uint24 step; // The step in percentages for adjusting the trailing order.
    }

    /**
     * @notice Represents the additional data specific to a Dollar-Cost Averaging (DCA) order.
     * @param period The period of buying, indicating the time interval between each purchase.
     * @param amountPerPeriod The amount of the base token to spend per period in the DCA strategy.
     */
    struct DCAOrderData {
        uint128 period; // The period of buying, indicating the time interval between each purchase.
        uint128 amountPerPeriod; //  The amount of the base token to spend per period in the DCA strategy.
    }

    /**
     * @notice This enum representing the actions that can be associated with an order.
     * @dev The actions include LOSS, PROFIT, DCA (Dollar-Cost Averaging), and TRAILING.
     * @dev LOSS: Specifies an order aiming to sell the base token when the target token's value falls below a certain threshold.
     * @dev PROFIT: Specifies an order aiming to sell the base token when the target token's value exceeds a certain threshold.
     * @dev DCA: Specifies an order using the Dollar-Cost Averaging strategy, where a fixed amount of the base token is periodically bought.
     * @dev TRAILING: Specifies an order using the trailing stop strategy, where the order adjusts its target based on the price movement.
     */
    enum Action {
        LOSS,
        PROFIT,
        DCA,
        TRAILING
    }

    /**
     * @notice Emitted when tokens are deposited into the contract.
     * @param operator The address of the operator performing the deposit.
     * @param token The address of the deposited token.
     * @param amount The amount of tokens deposited.
     */
    event Deposited(address operator, address token, uint256 amount);

    /**
     * @notice Emitted when two orders are bound together.
     * @param leftOrderId The ID of the left order in the binding.
     * @param rightOrderId The ID of the right order in the binding.
     */
    event OrdersBounded(uint256 leftOrderId, uint256 rightOrderId);

    /**
     * @notice Emitted when an order is canceled.
     * @param orderId The ID of the canceled order.
     */
    event OrderCanceled(uint256 orderId);

    /**
     * @notice Emitted when a new order is created.
     * @param orderId The ID of the newly created order.
     * @param userAddress The address of the user creating the order.
     */
    event OrderCreated(uint256 orderId, address userAddress);

    /**
     * @notice Emitted when an order is executed.
     * @param orderId The ID of the executed order.
     * @param validator The address of the validator who executed the order.
     */
    event OrderExecuted(uint256 orderId, address validator);

    /**
     * @notice Emitted when a new token is added to the contract.
     * @param token The address of the added token.
     */
    event TokenAdded(address token);

    /**
     * @notice Emitted when a token is removed from the contract.
     * @param token The address of the removed token.
     */
    event TokenRemoved(address token);

    /**
     * @notice Emitted when tokens are withdrawn from the contract.
     * @param operator The address of the operator performing the withdrawal.
     * @param token The address of the withdrawn token.
     * @param amount The amount of tokens withdrawn.
     */
    event Withdrawed(address operator, address token, uint256 amount);

    /**
     * @notice Retrieves the number of active orders.
     * @return The count of active orders.
     * @dev This function is read-only and can be called by anyone.
     */
    function activeOrdersLength() external view returns (uint256);

    /**
     * @notice Retrieves the active order ID at the specified index.
     * @param itemId The index of the active order in the active orders list.
     * @return The ID of the active order at the specified index.
     * @dev This function is read-only and can be called by anyone.
     * @dev Requires the itemId to be within the valid range of activeOrders length.
     */
    function activeOrderId(uint256 itemId) external view returns (uint256);

    /**
     * @notice Retrieves an array of active order IDs based on pagination parameters.
     * @param offset The number of skipped elements.
     * @param limit The number of items requested.
     * @return ordersIds An array of active order IDs.
     * @dev This function is read-only and can be called by anyone.
     */
    function activeOrdersIds(uint256 offset, uint256 limit) external view returns (uint256[] memory ordersIds);

    /**
     * @notice Checks the upkeep status and provides the necessary data for performing upkeep.
     * @param checkData Additional data for the upkeep check.
     * @return upkeepNeeded A boolean indicating whether upkeep is needed or not.
     * @return performData Encoded data containing the order IDs that require rebalance.
     * @dev This function is external and view-only.
     * @dev It calls the shouldRebalance function to retrieve the list of order IDs that need to be rebalanced.
     * @dev It sets upkeepNeeded to true if there are any orders that need to be rebalanced, and false otherwise.
     * @dev It encodes the list of order IDs into performData using the abi.encode function.
     * @dev Finally, it returns upkeepNeeded and performData.
     */
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice Returns the address of the fee recipient.
     * @return The address of the fee recipient.
     * @dev This function is read-only and can be called by anyone.
     */
    function getFeeRecipient() external view returns (address);

    /**
     * @notice Retrieves the current order counter.
     * @return The current order counter value.
     * @dev This function is read-only and can be called by anyone.
     */
    function getOrderCounter() external view returns (uint256);

    /**
     * @notice Returns the current protocol fee percentage.
     * @return The current protocol fee percentage.
     * @dev This function is read-only and can be called by anyone.
     */
    function getProtocolFee() external view returns (uint32);

    /**
     * @notice Retrieves the result token out value for a specific order ID.
     * @param orderId The ID of the order.
     * @return The result token out value for the order.
     * @dev This function is read-only and can be called by anyone.
     */
    function getResultTokenOut(uint256 orderId) external view returns (uint256);

    /**
     * @notice Returns the address of the UniswapHelperV3 contract.
     * @return The address of the UniswapHelperV3 contract.
     * @dev This function is read-only and can be called by anyone.
     */
    function getSwapHelper() external view returns (address);

    /**
     * @notice Checks if a token is whitelisted.
     * @param token The address of the token to check.
     * @return A boolean indicating whether the token is whitelisted or not.
     * @dev This function is read-only and can be called by anyone.
     */
    function getTokenStatus(address token) external view returns (bool);

    /**
     * @notice Retrieves the balance of a specific token for a user.
     * @param user The address of the user.
     * @param token The address of the token.
     * @return The balance of the token for the user.
     * @dev This function is read-only and can be called by anyone.
     */
    function getUserBalance(address user, address token) external view returns (uint256);

    /**
     * @notice Retrieves the array of order IDs associated with a user address.
     * @param userAddress The address of the user.
     * @return An array of order IDs associated with the user address.
     * @dev This function is read-only and can be called by anyone.
     */
    function getUserOrdersIds(address userAddress) external view returns (uint256[] memory);

    /**
     * @notice Retrieves detailed information about the user's orders.
     * @param userAddress The address of the user.
     * @return An array of OrderInfo structs containing detailed information about the user's orders.
     * @dev This function is read-only and can be called by anyone.
     */
    function getUserOrdersInfo(address userAddress) external view returns (OrderInfo[] memory);

    /**
     * @notice Checks if an active order with the given ID exists.
     * @param orderId The ID of the order.
     * @return A boolean indicating whether an active order with the given ID exists or not.
     * @dev This function is read-only and can be called by anyone.
     */
    function isActiveOrderExist(uint256 orderId) external view returns (bool);

    /**
     * @notice Checks if an order is valid and can be executed.
     * @param orderId The ID of the order to be checked.
     * @return bool True if the order is valid and can be executed, false otherwise.
     */
    function checkOrder(uint256 orderId) external view returns (bool);

    /**
     * @notice Retrieves detailed information about multiple orders.
     * @param ordersIds An array of order IDs.
     * @return orders An array of OrderInfo structs containing detailed information about the orders.
     * @dev This function is read-only and can be called by anyone.
     */
    function getOrdersInfo(uint256[] memory ordersIds) external view returns (OrderInfo[] memory orders);

    /**
     * @notice Retrieves the list of order IDs that need to be rebalanced.
     * @return An array of order IDs that require rebalance.
     * @dev Initializes an array of order IDs with the size of the active orders count.
     * @dev Iterates over the active orders and checks each order using the checkOrder function.
     * @dev If an order needs to be rebalanced, it adds the order ID to the ordersIds array.
     * @dev If an order does not need to be rebalanced, it increments the skipped counter.
     * @dev If any orders were skipped, it adjusts the length of the ordersIds array accordingly.
     * @dev Finally, it returns the array of order IDs that need to be rebalanced.
     */
    function shouldRebalance() external view returns (uint256[] memory);

    /**
     * @notice Adds multiple tokens to the whitelist.
     * @param tokens An array of token addresses to add.
     * @dev Only callable by an address with the ADMIN_ROLE.
     * @dev Requires each token address to be non-zero and not already in the whitelist.
     * @dev Emits a {TokenAdded} event for each token added to the whitelist.
     */
    function addTokensToWhitelist(address[] memory tokens) external;

    /**
     * @notice Binds two orders together.
     * @param leftOrderId The ID of the left order to bind.
     * @param rightOrderId The ID of the right order to bind.
     * @dev Requires both orders to belong to the calling user and not be DCA orders.
     * @dev Requires both orders to not be already bound with other orders.
     * @dev Updates the boundOrder field of each order to bind them together.
     * @dev Emits a {OrdersBounded} event upon successful binding of the orders.
     */
    function boundOrders(uint256 leftOrderId, uint256 rightOrderId) external;

    /**
     * @notice Cancels the specified orders.
     * @param ordersIds Array of order IDs to be canceled.
     * @dev Requires the orders to be active and belong to the calling user.
     * @dev Refunds the base tokens to the user balance.
     * @dev Emits a {OrderCanceled} event for each canceled order.
     */
    function cancelOrders(uint256[] memory ordersIds) external;

    /**
     * @notice Creates a new order.
     * @param order The order to create.
     * @return The ID of the created order.
     * @dev Requires various checks for the validity of the order.
     * @dev Transfers base tokens from the user to this contract if user balance on contract is insufficient.
     * @dev Adds the order to the active orders list and associates it with the user.
     * @dev Emits a {OrderCreated} event upon successful creation of the order.
     */
    function createOrder(Order memory order) external returns (uint256);

    /**
     * @notice Deposits an amount of tokens into the contract for a specific user.
     * @param token The address of the token to deposit.
     * @param amount The amount of tokens to deposit.
     * @return A boolean indicating the success of the deposit.
     * @dev Requires the token to be allowed in the whitelist.
     * @dev Transfers the specified amount of tokens from the user to this contract.
     * @dev Updates the user's token balance in the contract.
     * @dev Emits a {Deposited} event upon successful deposit.
     */
    function deposit(address token, uint256 amount) external returns (bool);

    /**
     * @notice Executes the orders specified by the given order IDs.
     * @param ordersIds An array of order IDs to be executed.
     * @return A boolean value indicating the success of the execution.
     * @dev Emits a {OrderExecuted} event for each executed order.
     */
    function executeOrders(uint256[] memory ordersIds) external returns (bool);

    /**
     * @notice Performs the upkeep based on the provided performData.
     * @param performData Encoded data containing the order IDs to be executed.
     * @dev This function is external and non-reentrant.
     * @dev Requires at least one order ID to be provided for execution.
     * @dev It decodes the performData to retrieve the order IDs.
     * @dev Calls the executeOrders function to execute the specified orders.
     * @dev Emits a {OrderExecuted} event for each executed order.
     */
    function performUpkeep(bytes calldata performData) external;

    /**
     * @notice Removes multiple tokens from the whitelist.
     * @param tokens An array of token addresses to remove.
     * @dev Only callable by an address with the ADMIN_ROLE.
     * @dev Removes each token address from the whitelist if it exists.
     * @dev Emits a {TokenRemoved} event for each token removed from the whitelist.
     */
    function removeTokensFromWhitelist(address[] memory tokens) external;

    /**
     * @notice Sets a new protocol fee percentage.
     * @param newProtocolFee The new protocol fee percentage to be set, represented as a decimal with 6 digits precision.
     * @dev Only the specified role can call this function.
     * @dev The new protocol fee must be less than 100% (represented as 1,000,000 in 6 digits precision).
     * @dev Emits a {ProtocolFeeSet} event.
     */
    function setProtocolFee(uint32 newProtocolFee) external;

    /**
     * @notice Withdraws an amount of tokens from the contract for a specific user.
     * @param token The address of the token to withdraw.
     * @param amount The amount of tokens to withdraw.
     * @return A boolean indicating the success of the withdrawal.
     * @dev Requires the user to have a sufficient balance of the specified token.
     * @dev Transfers the specified amount of tokens from the contract to the user.
     * @dev Updates the user's token balance in the contract.
     * @dev Emits a {Withdrawed} event upon successful withdrawal.
     */
    function withdraw(address token, uint256 amount) external returns (bool);
}
