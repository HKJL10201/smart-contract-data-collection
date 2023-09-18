pragma solidity 0.5.3;
pragma experimental ABIEncoderV2;

interface IExc {
    enum Side {
        BUY,
        SELL
    }

    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }

    struct Order {
        uint256 id;
        address trader;
        Side side;
        bytes32 ticker;
        uint256 amount;
        uint256 filled;
        uint256 price;
        uint256 date;
    }

    function getLastOrderID() external view returns (uint256);

    function getOrders(bytes32 ticker, Side side) external view returns (Order[] memory);

    function getTokens() external view returns (Token[] memory);

    function addToken(bytes32 ticker, address tokenAddress) external;

    function deposit(uint256 amount, bytes32 ticker) external;

    function withdraw(uint256 amount, bytes32 ticker) external;

    function makeLimitOrder(
        bytes32 ticker,
        uint256 amount,
        uint256 price,
        Side side
    ) external;

    function deleteLimitOrder(
        uint256 id,
        bytes32 ticker,
        Side side
    ) external returns (bool);

    function makeMarketOrder(
        bytes32 ticker,
        uint256 amount,
        Side side
    ) external;
}
