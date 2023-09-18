//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {AMMExchange} from "./Exchange.sol";

contract LeverageTrade is AMMExchange {
    uint64 public constant MAX_LEVERAGE = 10;
    AggregatorV3Interface internal eth_usd_price_feed;

    struct Account {
        uint256 collateral;
        uint64 totalLeverage;
        bool enabled;
    }

    // For a leveraged short position, `ethAmount` is the amount of ETH sold
    //  For a leveraged long position, `ethAmount` is the amount of ETH bought
    struct Position {
        uint256 ethAmount;
        uint256 leverage;
        uint256 lockedPrice; // ETH price at which position was opened
        Side side;
    }

    enum Side {
        LONG,
        SHORT
    }

    mapping(address => mapping(IERC20 => Account)) private accounts;
    mapping(address => mapping(IERC20 => Position[])) private positions;

    event DepositToken(
        address indexed account,
        address indexed token,
        uint256 indexed amount
    );

    event OpenPosition(
        address indexed account,
        uint64 indexed leverage,
        uint256 indexed amount,
        uint256 side
    );

    constructor(
        IERC20 twd,
        IERC20 usd,
        address ethUsdPriceFeed
    ) AMMExchange(twd, usd) {
        eth_usd_price_feed = AggregatorV3Interface(ethUsdPriceFeed);
    }

    function depositToken(IERC20 _token, uint256 _amount) external {
        _safeTransferFrom(_token, msg.sender, address(this), _amount);
        Account memory account = accounts[msg.sender][_token];

        if (!account.enabled) {
            account = Account(_amount, 0, true);
            accounts[msg.sender][_token] = account;
        } else {
            account.collateral = account.collateral + _amount;
            accounts[msg.sender][_token] = account;
        }

        emit DepositToken(msg.sender, address(_token), _amount);
    }

    function getAmountOut(uint256 _amount, uint256 _leverage)
        external
        pure
        returns (uint256)
    {
        return _amount * _leverage;
    }

    function getAmountOut2(uint256 _amount, uint256 _leverage)
        external
        pure
        returns (uint256)
    {
        return _amount / _leverage;
    }

    function getRemAccountValue(IERC20 _token) external view returns (uint256) {
        Account memory account = accounts[msg.sender][_token];
        return _getRemAccountValue(account);
    }

    function _getRemAccountValue(Account memory account)
        internal
        pure
        returns (uint256)
    {
        uint256 collateral = account.collateral;
        uint64 currentLeverage = account.totalLeverage;

        return (collateral * MAX_LEVERAGE) - (collateral * currentLeverage);
    }

    function openLongPosition(IERC20 _token, uint64 _leverage) external {
        Account memory account = accounts[msg.sender][_token];
        _openPosition(_token, account, _leverage, Side.LONG);
    }

    function openShortPosition(IERC20 _token, uint64 _leverage) external {
        Account memory account = accounts[msg.sender][_token];
        _openPosition(_token, account, _leverage, Side.SHORT);
    }

    function _openPosition(
        IERC20 _token,
        Account memory _account,
        uint64 _leverage,
        Side _side
    ) internal {
        uint256 collateral = _account.collateral;
        uint256 expectedPositionValue = _leverage * collateral;

        _precheck(_leverage, expectedPositionValue, _account); // sanity check

        uint256 ethPriceUSD = getEthUsd();
        uint256 postionValueETH = expectedPositionValue / ethPriceUSD;

        Position[] storage position = positions[msg.sender][_token];

        Position memory newposition;
        if (_side == Side.LONG) {
            newposition = Position(
                postionValueETH,
                _leverage,
                ethPriceUSD,
                Side.LONG
            );
        } else {
            newposition = Position(
                postionValueETH,
                _leverage,
                ethPriceUSD,
                Side.SHORT
            );
        }

        position.push(newposition);

        _account.totalLeverage = _account.totalLeverage + _leverage;
        accounts[msg.sender][_token] = _account;

        emit OpenPosition(msg.sender, _leverage, collateral, uint256(_side));
    }

    function getEthUsd() public view returns (uint256) {
        (, int256 answer, , , ) = eth_usd_price_feed.latestRoundData();

        return uint256(answer * 10**10); // convert answer from 8 to 18 decimlas
    }

    function _precheck(
        uint256 _leverage,
        uint256 _expectedPositionValue,
        Account memory _account
    ) internal pure {
        uint256 collateral = _account.collateral;
        require(
            _leverage <= MAX_LEVERAGE,
            "LeverageTrade: exceeded MAX_LEVERAGE"
        );

        require(collateral > 0, "LeverageTrade: insufficient collateral");

        uint256 remAccountValue = _getRemAccountValue(_account);
        require(
            _expectedPositionValue <= remAccountValue,
            "LeverageTrade: exceeded MAX position"
        );
    }

    function getAccount(address _account, IERC20 _token)
        external
        view
        returns (Account memory)
    {
        return accounts[_account][_token];
    }

    function getPositions(IERC20 _token, address _account)
        external
        view
        returns (Position[] memory)
    {
        return positions[_account][_token];
    }
}
