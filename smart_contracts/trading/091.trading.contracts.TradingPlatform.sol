// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import {ITradingPlatform} from "./interfaces/ITradingPlatform.sol";
import {IERC20WithDecimals} from "./interfaces/IERC20WithDecimals.sol";
import {ISwapHelperUniswapV3} from "./interfaces/ISwapHelperUniswapV3.sol";
import {Counters} from "@openzeppelin/contractsV4/utils/Counters.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contractsV4/token/ERC20/utils/SafeERC20.sol";
import {AccessControlEnumerable, EnumerableSet} from "@openzeppelin/contractsV4/access/AccessControlEnumerable.sol";
import {ReentrancyGuard} from "@openzeppelin/contractsV4/security/ReentrancyGuard.sol";

/**
 * @title The contract implements the token trading platform with different trading tools
 */
contract TradingPlatform is ITradingPlatform, AccessControlEnumerable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Representing the admin role.
    uint32 public constant PRECISION = 1000000; // Precision constant used for percentage calculations. Represents the decimal precision up to six decimal places.

    uint32 private secondsAgoDefault = 30; // Default value for the number of seconds ago used in average price calculations.
    uint32 private protocolFee; //  Protocol fee applied to certain operations in the contract. Represents the fee percentage applied to specific operations within the contract.
    address private uniswapHelperV3; // Address of the Uniswap helper contract (version 3) used for swaps.
    address private feeRecipient; // Address of the recipient of protocol fees.  Represents the address where the protocol fees are sent to.

    mapping(uint256 => uint256) private additionalInformation; // Mapping to store additional information related to orders. Used to store the last execution time for DCA orders or the last execution price for trailing orders.
    mapping(uint256 => uint256) private resultTokenOut; // Mapping to store the result token output for orders. aps the order ID to the amount of token received as a result of executing the order.
    mapping(uint256 => Order) private orderInfo; // Mapping to store order information. Maps the order ID to the order struct, containing detailed order information.
    mapping(address => uint256[]) private userOrders; //  Mapping to store user orders. Maps the user's address to an array of order IDs representing all the orders associated with the user.
    mapping(address => mapping(address => uint256)) private balances; // Maps the user's address to a mapping of token addresses and their corresponding balances.

    Counters.Counter private orderCounter; // Counter to keep track of the number of orders. sed to count the total number of orders in the contract.
    EnumerableSet.AddressSet private tokensWhiteList; // Set of tokens in the whitelist. Contains the addresses of tokens that are allowed within the contract.
    EnumerableSet.UintSet private activeOrders; // Set of active orders. Contains the IDs of the currently active orders within the contract.

    /**
     * @dev See {ITradingPlatform}
     */
    function activeOrdersLength() external view returns (uint256) {
        return activeOrders.length();
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function activeOrderId(uint256 itemId) external view returns (uint256) {
        require(itemId < activeOrders.length(), "Invalid token id");
        return activeOrders.at(itemId);
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function activeOrdersIds(uint256 offset, uint256 limit) external view returns (uint256[] memory ordersIds) {
        uint256 ordersCount = activeOrders.length();
        if (offset >= ordersCount) return new uint256[](0);
        uint256 to = offset + limit;
        if (ordersCount < to) to = ordersCount;
        ordersIds = new uint256[](to - offset);
        for (uint256 i = 0; i < ordersIds.length; i++) ordersIds[i] = activeOrders.at(offset + i);
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData) {
        (uint128 performOffset, uint128 performLimit) = abi.decode(checkData, (uint128, uint128));
        uint256[] memory ordersIds = shouldRebalance();
        // control perform part hire for gas saving
        if (performOffset >= ordersIds.length) return (upkeepNeeded, abi.encode(new uint256[](0)));
        uint256 performTo = (performOffset + performLimit) > ordersIds.length
            ? ordersIds.length
            : performOffset + performLimit;
        uint256[] memory checkArray = new uint256[](performTo - performOffset);
        for (uint256 i = 0; i < checkArray.length; i++) {
            checkArray[i] = ordersIds[performOffset + i];
        }
        upkeepNeeded = ordersIds.length > 0;
        performData = abi.encode(checkArray);
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function getOrderCounter() external view returns (uint256) {
        return orderCounter.current();
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function getProtocolFee() external view returns (uint32) {
        return protocolFee;
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function getResultTokenOut(uint256 orderId) external view returns (uint256) {
        return resultTokenOut[orderId];
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function getSwapHelper() external view returns (address) {
        return uniswapHelperV3;
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function getTokenStatus(address token) external view returns (bool) {
        return tokensWhiteList.contains(token);
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function getUserBalance(address user, address token) external view returns (uint256) {
        return balances[user][token];
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function getUserOrdersIds(address userAddress) external view returns (uint256[] memory) {
        return userOrders[userAddress];
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function getUserOrdersInfo(address userAddress) external view returns (OrderInfo[] memory) {
        uint256[] memory userOrdersIds = userOrders[userAddress];
        return getOrdersInfo(userOrdersIds);
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function isActiveOrderExist(uint256 orderId) external view returns (bool) {
        return activeOrders.contains(orderId);
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function checkOrder(uint256 orderId) public view returns (bool) {
        if (!activeOrders.contains(orderId)) return false; // Not active
        Order memory order = orderInfo[orderId];
        if ((order.action == Action.PROFIT || order.action == Action.LOSS) && order.expiration < block.timestamp) {
            return false;
        }
        if (order.action == Action.DCA) {
            DCAOrderData memory decodedData = abi.decode(order.data, (DCAOrderData));
            if (block.timestamp >= decodedData.period + additionalInformation[orderId]) return true;
            return false;
        }
        if (order.action == Action.TRAILING) {
            TrailingOrderData memory decodedData = abi.decode(order.data, (TrailingOrderData));
            uint256 expectedAmountOutForTrailing = ISwapHelperUniswapV3(uniswapHelperV3).getAmountOut(
                order.baseToken,
                order.targetToken,
                decodedData.baseAmount,
                order.pairFee,
                secondsAgoDefault
            );
            uint256 lastBuyingAmountOut = additionalInformation[orderId];
            if (
                (lastBuyingAmountOut == 0 && expectedAmountOutForTrailing >= order.aimTargetTokenAmount) ||
                (lastBuyingAmountOut != 0 && // true
                    (expectedAmountOutForTrailing >=
                        lastBuyingAmountOut + getPercent(lastBuyingAmountOut, decodedData.step) ||
                        expectedAmountOutForTrailing <
                        lastBuyingAmountOut - getPercent(lastBuyingAmountOut, decodedData.step)))
            ) return true;
        }
        uint256 expectedAmountOut = ISwapHelperUniswapV3(uniswapHelperV3).getAmountOut(
            order.baseToken,
            order.targetToken,
            order.baseAmount,
            order.pairFee,
            secondsAgoDefault
        );
        if (
            order.action == Action.LOSS &&
            expectedAmountOut <= order.aimTargetTokenAmount &&
            expectedAmountOut > order.minTargetTokenAmount
        ) return true;
        if (order.action == Action.PROFIT && expectedAmountOut >= order.aimTargetTokenAmount) {
            return true;
        }
        return false;
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function getOrdersInfo(uint256[] memory ordersIds) public view returns (OrderInfo[] memory orders) {
        orders = new OrderInfo[](ordersIds.length);
        for (uint256 i = 0; i < ordersIds.length; i++) {
            orders[i] = OrderInfo(
                ordersIds[i],
                orderInfo[ordersIds[i]],
                additionalInformation[ordersIds[i]],
                resultTokenOut[ordersIds[i]],
                activeOrders.contains(ordersIds[i])
            );
        }
        return orders;
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function shouldRebalance() public view returns (uint256[] memory) {
        //get Active Orders
        uint256 ordersCount = activeOrders.length();
        uint256[] memory ordersIds = new uint256[](ordersCount);
        uint256 skipped = 0;
        for (uint256 i = 0; i < ordersCount; i++) {
            uint256 orderId = activeOrders.at(i);
            if (checkOrder(orderId)) {
                ordersIds[i - skipped] = orderId;
            } else {
                skipped++;
            }
        }
        if (skipped > 0) {
            uint256 newLength = ordersCount - skipped;
            assembly {
                mstore(ordersIds, newLength)
            }
        }
        return ordersIds;
    }

    /**
     * @notice Initializes the TradingPlatform contract with the specified parameters.
     * @param uniswapHelperV3_ The address of the UniswapHelperV3 contract.
     * @param admin The address of the contract admin.
     * @param protocolFee_ The protocol fee percentage, represented as a decimal with 6 digits precision.
     * @param feeRecipient_ The address where the protocol fees will be sent to.
     * @dev The UniswapHelperV3 address, admin address, and fee recipient address must not be zero addresses.
     * @dev The protocol fee must be less than 100% (represented as 1,000,000 in 6 digits precision).
     * @dev Sets the DEFAULT_ADMIN_ROLE and ADMIN_ROLE roles to the admin address.
     */
    constructor(address uniswapHelperV3_, address admin, uint32 protocolFee_, address feeRecipient_) {
        require(uniswapHelperV3_ != address(0), "UniswapHelperV3 zero address");
        require(admin != address(0), "Admin zero address");
        require(feeRecipient_ != address(0), "Fee recipient zero address");
        require(protocolFee_ < PRECISION, "Fee is 100% or greater");
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(ADMIN_ROLE, admin);
        uniswapHelperV3 = uniswapHelperV3_;
        protocolFee = protocolFee_;
        feeRecipient = feeRecipient_;
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function addTokensToWhitelist(address[] memory tokens) external onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != address(0), "Token zero address check");
            if (tokensWhiteList.contains(tokens[i])) continue;
            tokensWhiteList.add(tokens[i]);
            emit TokenAdded(tokens[i]);
        }
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function boundOrders(uint256 leftOrderId, uint256 rightOrderId) external nonReentrant {
        require(leftOrderId != 0 && rightOrderId != 0 && leftOrderId != rightOrderId, "Non-compatible orders");
        require(
            orderInfo[leftOrderId].userAddress == msg.sender && orderInfo[rightOrderId].userAddress == msg.sender,
            "Not your order"
        );
        require(
            orderInfo[leftOrderId].action != Action.DCA && orderInfo[rightOrderId].action != Action.DCA,
            "Can't bound DCA"
        );
        require(
            orderInfo[leftOrderId].boundOrder == 0 && orderInfo[rightOrderId].boundOrder == 0,
            "Orders already bounded"
        );
        orderInfo[leftOrderId].boundOrder = rightOrderId;
        orderInfo[rightOrderId].boundOrder = leftOrderId;
        emit OrdersBounded(leftOrderId, rightOrderId);
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function cancelOrders(uint256[] memory ordersIds) external nonReentrant {
        for (uint256 i = 0; i < ordersIds.length; i++) {
            if (!activeOrders.contains(ordersIds[i])) continue;
            Order memory order = orderInfo[ordersIds[i]];
            require(order.userAddress == msg.sender, "Not your order");
            activeOrders.remove(ordersIds[i]);
            balances[order.userAddress][order.baseToken] += order.baseAmount;
            emit OrderCanceled(ordersIds[i]);
        }
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function createOrder(Order memory order) external nonReentrant returns (uint256) {
        require(order.userAddress == msg.sender, "Wrong user address");
        require(order.baseToken != address(0), "Zero address check");
        require(order.targetToken != address(0), "Zero address check");
        require(order.baseToken != order.targetToken, "Tokens must be different");
        require(order.baseAmount > 0, "Amount in must be gt 0");
        require(order.slippage > 0 && order.slippage < 50000, "Unsafe slippage");
        if (order.action != Action.DCA) require(order.aimTargetTokenAmount > 0, "Aim amount must be gt 0");
        if (order.action == Action.PROFIT || order.action == Action.LOSS) {
            require(order.expiration > block.timestamp, "Wrong expiration date");
        }
        require(
            tokensWhiteList.contains(order.baseToken) && tokensWhiteList.contains(order.targetToken),
            "Token not allowed"
        );
        orderCounter.increment();
        uint256 orderId = orderCounter.current();
        if (order.action == Action.DCA) {
            DCAOrderData memory decodedData = abi.decode(order.data, (DCAOrderData));
            require(decodedData.amountPerPeriod > 0, "Zero amount to swap");
            additionalInformation[orderId] = block.timestamp;
        } else if (order.action == Action.TRAILING) {
            TrailingOrderData memory decodedData = abi.decode(order.data, (TrailingOrderData));
            require(decodedData.fixingPerStep > 0, "Zero amount to swap");
            require(decodedData.baseAmount == order.baseAmount, "Wrong base amount");
            require(decodedData.step > 0, "Wrong step amount");
        }
        if (order.boundOrder != 0) {
            Order memory boundOrder = orderInfo[order.boundOrder];
            require(order.action != Action.DCA && boundOrder.action != Action.DCA, "Can't bound DCA order");
            require(boundOrder.userAddress == msg.sender, "Bound order is not yours");
            require(activeOrders.contains(order.boundOrder), "Bound order is not active");
            require(boundOrder.boundOrder == 0, "Bound order already bounded");
            orderInfo[order.boundOrder].boundOrder = orderId;
        }
        activeOrders.add(orderId);
        userOrders[msg.sender].push(orderId);
        orderInfo[orderId] = order;

        uint256 baseTokenUserBalance = balances[msg.sender][order.baseToken];
        if (baseTokenUserBalance < order.baseAmount) {
            uint256 neededAmount = order.baseAmount - baseTokenUserBalance;
            if (baseTokenUserBalance != 0) balances[msg.sender][order.baseToken] = 0;
            IERC20(order.baseToken).safeTransferFrom(msg.sender, address(this), neededAmount);
        } else {
            balances[msg.sender][order.baseToken] -= order.baseAmount;
        }
        emit OrderCreated(orderId, msg.sender);
        return orderId;
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function deposit(address token, uint256 amount) external nonReentrant returns (bool) {
        require(tokensWhiteList.contains(token), "Token not allowed");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        balances[msg.sender][token] += amount;
        emit Deposited(msg.sender, token, amount);
        return true;
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function executeOrders(uint256[] memory ordersIds) public nonReentrant returns (bool) {
        for (uint256 i = 0; i < ordersIds.length; i++) {
            if (!checkOrder(ordersIds[i])) {
                continue;
            }
            executeOrder(ordersIds[i]);
        }
        return true;
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function performUpkeep(bytes calldata performData) external {
        uint256[] memory ordersIds = abi.decode(performData, (uint256[]));
        require(ordersIds.length > 0, "Nothing for execution");
        executeOrders(ordersIds);
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function removeTokensFromWhitelist(address[] memory tokens) external onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (!tokensWhiteList.contains(tokens[i])) continue;
            tokensWhiteList.remove(tokens[i]);
            emit TokenRemoved(tokens[i]);
        }
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function setProtocolFee(uint32 newProtocolFee) external onlyRole(ADMIN_ROLE) {
        require(newProtocolFee < PRECISION, "newProtocolFee can't be gt 100%");
        protocolFee = newProtocolFee;
    }

    /**
     * @dev See {ITradingPlatform}
     */
    function withdraw(address token, uint256 amount) external nonReentrant returns (bool) {
        require(balances[msg.sender][token] >= amount, "Amount exceed balance");
        balances[msg.sender][token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdrawed(msg.sender, token, amount);
        return true;
    }

    /**
     * @notice Executes an individual order based on the provided order ID.
     * @param orderId ID of the order to be executed.
     * @dev This function is internal and should not be called directly from outside the contract.
     * @dev Emits a {OrderExecuted} event.
     */
    function executeOrder(uint256 orderId) internal {
        Order memory order = orderInfo[orderId];
        uint128 amountToSwap = order.baseAmount;
        if (order.action == Action.TRAILING) {
            TrailingOrderData memory decodedData = abi.decode(order.data, (TrailingOrderData));
            uint256 expectedAmountOut = ISwapHelperUniswapV3(uniswapHelperV3).getAmountOut(
                order.baseToken,
                order.targetToken,
                decodedData.baseAmount,
                order.pairFee,
                secondsAgoDefault
            );
            uint256 lastBuyingAmountOut = additionalInformation[orderId];
            if (
                lastBuyingAmountOut == 0 ||
                expectedAmountOut >= lastBuyingAmountOut + getPercent(lastBuyingAmountOut, decodedData.step)
            ) {
                if (decodedData.fixingPerStep >= order.baseAmount) {
                    activeOrders.remove(orderId); //update active orders set
                } else {
                    amountToSwap = decodedData.fixingPerStep;
                }
            } else if (expectedAmountOut < lastBuyingAmountOut - getPercent(lastBuyingAmountOut, decodedData.step)) {
                amountToSwap = order.baseAmount;
                activeOrders.remove(orderId); //update active orders set
            }
            additionalInformation[orderId] = expectedAmountOut;
            orderInfo[orderId].baseAmount -= amountToSwap;
        } else if (order.action == Action.DCA) {
            DCAOrderData memory decodedData = abi.decode(order.data, (DCAOrderData));
            amountToSwap = decodedData.amountPerPeriod;
            if (decodedData.amountPerPeriod >= order.baseAmount) {
                amountToSwap = order.baseAmount;
                activeOrders.remove(orderId); //update active orders set
            }
            // update storage
            additionalInformation[orderId] = block.timestamp;
            orderInfo[orderId].baseAmount -= amountToSwap;
        } else if (order.action == Action.LOSS || order.action == Action.PROFIT) {
            activeOrders.remove(orderId); //update active orders set
            if (order.boundOrder != 0) {
                if (activeOrders.contains(order.boundOrder)) {
                    Order memory boundOrder = orderInfo[order.boundOrder];
                    activeOrders.remove(order.boundOrder);
                    balances[boundOrder.userAddress][boundOrder.baseToken] += boundOrder.baseAmount;
                    emit OrderCanceled(order.boundOrder);
                } // remove bound orders and refund tokens to user balance
            }
        }
        IERC20(order.baseToken).approve(uniswapHelperV3, amountToSwap);
        uint256 amountOut = ISwapHelperUniswapV3(uniswapHelperV3).swapWithCustomSlippage(
            address(this),
            order.baseToken,
            order.targetToken,
            amountToSwap,
            order.pairFee,
            order.slippage
        );
        uint256 feeAmount = calculateFee(amountOut, protocolFee);
        if (order.action == Action.LOSS || order.action == Action.PROFIT)
            require(order.minTargetTokenAmount < amountOut - feeAmount, "Unfair exchange");
        balances[feeRecipient][order.targetToken] += feeAmount; // update fee balance
        balances[order.userAddress][order.targetToken] += amountOut - feeAmount; // update user balance
        resultTokenOut[orderId] += amountOut - feeAmount; // save amount that we get from this order execution
        emit OrderExecuted(orderId, msg.sender);
    }

    /**
     * @notice Calculates the fee amount based on the given token amount.
     * @param amount The token amount for which the fee is calculated.
     * @return uint256 The calculated fee amount.
     */
    function calculateFee(uint256 amount, uint32 protocolFeePercent) internal pure returns (uint256) {
        return (amount * protocolFeePercent) / PRECISION;
    }

    /**
     * @notice Calculates the percentage of an amount.
     * @param amount The base amount.
     * @param percent The percentage value, represented as a decimal with 6 digits precision.
     * @return uint256 The calculated percentage amount.
     */
    function getPercent(uint256 amount, uint24 percent) internal pure returns (uint256) {
        return (amount * percent) / PRECISION;
    }
}
