pragma solidity 0.5.3;
pragma experimental ABIEncoderV2;

import "../contracts/libraries/token/ERC20/ERC20.sol";
import "../contracts/libraries/math/SafeMath.sol";
import "../contracts/libraries/math/Math.sol";
import "./IExc.sol";

contract Exc is IExc {
    using SafeMath for uint256;
    using SafeMath for uint256;

    /// @notice these declarations are incomplete. You will still need a way to store the orderbook, the balances
    /// of the traders, and the IDs of the next trades and orders. Reference the NewTrade event and the IExc
    /// interface for more details about orders and sides.
    mapping(bytes32 => Token) public tokens;
    bytes32[] public tokenList;
    Token[] public tokenArray;
    bytes32 constant PIN = bytes32("PIN"); // pine

    // Wallet --> Trader balances by token
    mapping(address => mapping(bytes32 => uint256)) public traderBalances;

    // The orderBook is a mapping of token ticker to a mapping of trade side to an array of orders sorted by price.
    // The array is sorted in ascending order for sell orders.
    // The array is sorted in descending order for buy orders.
    mapping(bytes32 => mapping(uint8 => Order[])) public orderBook;

    // Last order ID
    uint256 private lastOrderId;
    bool private isInitialized;

    // The next trade ID
    uint256 private nextTradeId;

    /// @notice an event representing all the needed info regarding a new trade on the exchange
    event NewTrade(
        uint256 tradeId,
        uint256 orderId,
        bytes32 indexed ticker,
        address indexed trader1,
        address indexed trader2,
        uint256 amount,
        uint256 price,
        uint256 date
    );

    /// @notice an event representing all the needed info regarding a new order on the exchange
    event NewOrder(
        uint256 orderId,
        bytes32 indexed ticker,
        address indexed trader,
        uint256 amount,
        uint256 price,
        uint256 date
    );

    /// @notice an event representing all the needed info regarding a cancel order on the exchange
    event DeleteOrder(
        uint256 orderId,
        bytes32 indexed ticker,
        address indexed trader,
        uint256 date
    );

    /// @notice an event representing all the needed info regarding a filled limit order on the exchange
    event FilledLimitOrder(
        uint256 orderId,
        bytes32 indexed ticker,
        address indexed trader,
        uint256 date
    );

    /// @notice an event representing all the needed info regarding a deposit on the exchange
    event Deposit(address indexed trader, uint256 amount, bytes32 ticker, uint256 date);

    /// @notice an event representing all the needed info regarding a withdrawal on the exchange
    event Withdrawal(address indexed trader, uint256 amount, bytes32 ticker, uint256 date);

    // Gets the last order ID
    function getLastOrderID() external view returns (uint256) {
        return lastOrderId;
    }

    // todo: implement getOrders, which simply returns the orders for a specific token on a specific side
    function getOrders(bytes32 ticker, Side side)
        external
        view
        tokenExists(ticker)
        returns (Order[] memory)
    {
        return orderBook[ticker][uint8(side)];
    }

    // todo: implement getTokens, which simply returns an array of the tokens currently traded on in the exchange
    function getTokens() external view returns (Token[] memory) {
        return tokenArray;
    }

    // todo: implement addToken, which should add the token desired to the exchange by interacting with tokenList and tokens
    function addToken(bytes32 ticker, address tokenAddress) external {
        if (tokens[ticker].tokenAddress != address(0)) {
            return; // Token already exists
        }
        tokenList.push(ticker);
        tokens[ticker] = Token(ticker, tokenAddress);
        tokenArray.push(tokens[ticker]);
    }

    // todo: implement deposit, which should deposit a certain amount of tokens from a trader to their on-exchange wallet,
    // based on the wallet data structure you create and the IERC20 interface methods. Namely, you should transfer
    // tokens from the account of the trader on that token to this smart contract, and credit them appropriately
    function deposit(uint256 amount, bytes32 ticker) external tokenExists(ticker) {
        IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
        traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(amount);
        emit Deposit(msg.sender, amount, ticker, now);
    }

    // todo: implement withdraw, which should do the opposite of deposit. The trader should not be able to withdraw more than
    // they have in the exchange.
    function withdraw(uint256 amount, bytes32 ticker) external tokenExists(ticker) {
        // Check if the trader has enough tokens to withdraw
        require(traderBalances[msg.sender][ticker] >= amount);

        traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(amount);
        IERC20(tokens[ticker].tokenAddress).transfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount, ticker, now);
    }

    // todo: implement makeLimitOrder, which creates a limit order based on the parameters provided. This method should only be
    // used when the token desired exists and is not pine. This method should not execute if the trader's token or pine balances
    // are too low, depending on side. This order should be saved in the orderBook
    //
    // todo: implement a sorting algorithm for limit orders, based on best prices for market orders having the highest priority.
    // i.e., a limit buy order with a high price should have a higher priority in the orderbook.
    function makeLimitOrder(
        bytes32 ticker,
        uint256 amount,
        uint256 price,
        Side side
    ) external tokenExists(ticker) notPine(ticker) {
        // check if trader has enough tokens
        if (side == Side.BUY) {
            traderBalances[msg.sender][PIN].sub(amount.mul(price));
        } else {
            traderBalances[msg.sender][ticker].sub(amount);
        }

        // create the order and add it to the orderbook
        if (isInitialized) {
            lastOrderId++;
        } else {
            isInitialized = true;
        }
        Order memory order = Order(lastOrderId, msg.sender, side, ticker, amount, 0, price, now);
        orderBook[ticker][uint8(side)].push(order);

        bubbleSort(ticker, side); // sort the orderbook

        // fire the event
        emit NewOrder(lastOrderId, ticker, msg.sender, amount, price, now);
    }

    // todo: implement deleteLimitOrder, which will delete a limit order from the orderBook as long as the same trader is deleting
    // it.
    function deleteLimitOrder(
        uint256 id,
        bytes32 ticker,
        Side side
    ) external tokenExists(ticker) returns (bool) {
        // find the order in the orderbook
        for (uint256 i = 0; i < orderBook[ticker][uint8(side)].length; i++) {
            // for each order
            if (orderBook[ticker][uint8(side)][i].id == id) {
                // if the order is found
                // check if the trader is deleting the order
                require(orderBook[ticker][uint8(side)][i].trader == msg.sender);

                // delete the order
                orderBook[ticker][uint8(side)][i] = orderBook[ticker][uint8(side)][
                    orderBook[ticker][uint8(side)].length - 1
                ];
                orderBook[ticker][uint8(side)].pop();

                bubbleSort(ticker, side); // sort the orderbook

                // fire the event
                emit DeleteOrder(id, ticker, msg.sender, now);
                return true;
            }
        }
        return false; // order not found
    }

    // todo: implement makeMarketOrder, which will execute a market order on the current orderbook. The market order need not be
    // added to the book explicitly, since it should execute against a limit order immediately. Make sure you are getting rid of
    // completely filled limit orders!
    function makeMarketOrder(
        bytes32 ticker,
        uint256 amount,
        Side side
    ) external tokenExists(ticker) notPine(ticker) {
        uint256 amountLeft = amount;

        if (side == Side.BUY) {
            // if the trader is buying tokens from the exchange

            while (amountLeft > 0) {
                // buy tokens from the market until the market order is satisified

                Order memory order = getBestOrder(ticker, Side.SELL); // get the best SELL order in the orderbook
                uint256 amountToBuy = Math.min(amountLeft, order.amount); // get the amount of tokens to buy
                uint256 total = order.price.mul(amountToBuy); // get the total price of the order

                // check if the limit order trader has enough tokens to sell
                if (traderBalances[order.trader][ticker] < amountToBuy) {
                    order.amount = 0; // set the order amount to 0 to indicate that the order should be deleted
                    checkIfOrderFilled(order); // delete order
                    continue; // skip this order
                }

                // check if the trader has enough pine to buy
                require(traderBalances[msg.sender][PIN] >= total);

                // charge/pay the limit order trader
                traderBalances[order.trader][ticker] = traderBalances[order.trader][ticker].sub(
                    amountToBuy
                );
                traderBalances[order.trader][PIN] = traderBalances[order.trader][PIN].add(total);

                // charge/pay the market order trader
                traderBalances[msg.sender][PIN] = traderBalances[msg.sender][PIN].sub(total);
                traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(
                    amountToBuy
                );

                amountLeft = amountLeft.sub(amountToBuy);
                order.filled = order.filled.add(amountToBuy);
                order.amount = order.amount.sub(amountToBuy);

                checkIfOrderFilled(order); // check if the order is completely filled, delete it if it is

                // Emit a NewTrade event
                emit NewTrade(
                    nextTradeId++,
                    order.id,
                    ticker,
                    order.trader,
                    msg.sender,
                    amountToBuy,
                    order.price,
                    now
                );
            }
        } else {
            // if the trader is selling tokens to the exchange
            require(traderBalances[msg.sender][ticker] >= amount);

            while (amountLeft > 0) {
                // sell tokens to the market until the market order is satisfied

                Order memory order = getBestOrder(ticker, Side.BUY); // get the best BUY order in the orderbook
                uint256 amountToSell = Math.min(amountLeft, order.amount); // get the amount of tokens to sell
                uint256 total = order.price.mul(amountToSell); // get the total price of the order

                // check if the limit order trader has enough pine to buy
                if (traderBalances[order.trader][PIN] < total) {
                    order.amount = 0; // set the order amount to 0 to indicate that the order should be deleted
                    checkIfOrderFilled(order); // delete order
                    continue; // skip this order
                }

                // charge/pay the limit order trader
                traderBalances[order.trader][PIN] = traderBalances[order.trader][PIN].sub(total);
                traderBalances[order.trader][ticker] = traderBalances[order.trader][ticker].add(
                    amountToSell
                );

                // charge/pay the market order trader
                traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(
                    amountToSell
                );
                traderBalances[msg.sender][PIN] = traderBalances[msg.sender][PIN].add(total);

                amountLeft = amountLeft.sub(amountToSell);
                order.filled = order.filled.add(amountToSell);
                order.amount = order.amount.sub(amountToSell);

                checkIfOrderFilled(order); // check if the order is completely filled, delete it if it is

                // Emit a NewTrade event
                emit NewTrade(
                    nextTradeId++,
                    order.id,
                    ticker,
                    order.trader,
                    msg.sender,
                    amountToSell,
                    order.price,
                    now
                );
            }
        }
    }

    // Get the best order in the orderbook for a given side and ticker
    function getBestOrder(bytes32 ticker, Side side) internal view returns (Order memory order) {
        require(orderBook[ticker][uint8(side)].length > 0); // make sure there are orders in the orderbook
        return orderBook[ticker][uint8(side)][0];
    }

    // check if the order is filled, if so delete the order from the orderbook
    function checkIfOrderFilled(Order memory order) internal returns (bool) {
        if (order.amount <= 0) {
            // if the order is completely filled, delete it
            orderBook[order.ticker][uint8(order.side)][0] = orderBook[order.ticker][
                uint8(order.side)
            ][orderBook[order.ticker][uint8(order.side)].length - 1];
            orderBook[order.ticker][uint8(order.side)].pop();

            bubbleSort(order.ticker, order.side); // sort the orderbook

            // emit the event
            emit FilledLimitOrder(order.id, order.ticker, order.trader, now);
            return true;
        } else {
            // if the order is not completely filled, update it
            orderBook[order.ticker][uint8(order.side)][0] = order;
            return false;
        }
    }

    // modifiers for methods as detailed in handout:

    // tokenExists is a modifier for methods that take in a ticker. It should return true if the token exists, and false otherwise.
    modifier tokenExists(bytes32 ticker) {
        require(tokens[ticker].ticker == ticker);
        _;
    }

    // notPine is a modifier for methods that take in a ticker. It should return true if the token is not pine, and false otherwise.
    modifier notPine(bytes32 ticker) {
        require(ticker != PIN);
        _;
    }

    // Sort the orderbook for a given ticker and side by price in ascending order for sell orders and in descending order for buy orders.
    // Uses bubble sort and sorts in place.
    function bubbleSort(bytes32 ticker, Side side) internal {
        if (side == Side.SELL) {
            // Sell orders are sorted in ascending order by price
            for (uint256 i = 0; i < orderBook[ticker][uint8(side)].length; i++) {
                // for each order
                for (uint256 j = 0; j < orderBook[ticker][uint8(side)].length - i - 1; j++) {
                    // for each order after the current order
                    if (
                        orderBook[ticker][uint8(side)][j].price >
                        orderBook[ticker][uint8(side)][j + 1].price
                    ) {
                        // if the price of the current order is greater than the price of the next order, swap
                        Order memory temp = orderBook[ticker][uint8(side)][j];
                        orderBook[ticker][uint8(side)][j] = orderBook[ticker][uint8(side)][j + 1];
                        orderBook[ticker][uint8(side)][j + 1] = temp;
                    }
                }
            }
        } else {
            // Buy orders are sorted in descending order by price
            for (uint256 i = 0; i < orderBook[ticker][uint8(side)].length; i++) {
                // for each order
                for (uint256 j = 0; j < orderBook[ticker][uint8(side)].length - i - 1; j++) {
                    // for each order after the current order
                    if (
                        orderBook[ticker][uint8(side)][j].price <
                        orderBook[ticker][uint8(side)][j + 1].price
                    ) {
                        // if the price of the current order is less than the price of the next order, swap
                        Order memory temp = orderBook[ticker][uint8(side)][j];
                        orderBook[ticker][uint8(side)][j] = orderBook[ticker][uint8(side)][j + 1];
                        orderBook[ticker][uint8(side)][j + 1] = temp;
                    }
                }
            }
        }
    }
}
