// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

/**
 * @title   Multiple Moving Average Crossover Indicator
 * @author  pblivin0x
 * @notice  Consider two groups of moving averages: 
 *          S, a group of n short term moving averages and L, a group of m long term moving averages. 
 *
 *          S = [S1, S2, ..., Sn]
 *          L = [L1, L2, ..., Lm]
 *
 *          An indicator MMA() can be constructed as follows
 *          - bullish if min(S) > max(L)
 *          - bearish if max(S) < min(L)
 *          - uncertain otherwise
 *
 *          The uncertain case, when the short term and long term groups of moving averages overlap, 
 *          can be considered either bullish (risk-on) or bearish (risk-off) depending on manager preference.       
 *
 *          This indicator uses arithmetic mean ticks from Uniswap V3 pools acting as on-chain oracles  
 *          https://docs.uniswap.org/protocol/concepts/V3-overview/oracle
 */
contract MultipleMovingAverageCrossoverIndicator
{
    /* ============ Events ============ */

    /// @notice Emitted when the operator is changed
    /// @param _oldOperator Address of the old manager
    /// @param _newOperator Address of the new manager
    event OperatorChanged(
        address _oldOperator,
        address _newOperator
    );

    /// @notice Emitted when the Uniswap V3 pool is changed
    /// @param _oldPool Address of the old pool
    /// @param _newPool Address of the new pool
    event PoolChanged(
        IUniswapV3Pool _oldPool,
        IUniswapV3Pool _newPool
    );

    /// @notice Emitted when the uncertain condition is changed
    /// @param _oldUncertainIsBullish Old uncertain condition
    /// @param _newUncertainIsBullish New uncertain condition
    event UncertainIsBullishChanged(
        bool _oldUncertainIsBullish,
        bool _newUncertainIsBullish
    );

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the indicator operator
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Must be operator");
        _;
    }

    /* ============ State Variables ============ */

    // Address of the Uniswap V3 pool to be used as moving average oracle
    IUniswapV3Pool public pool;

    // Boolean to indicate whether indicator uncertain case is bullish or bearish
    bool public uncertainIsBullish;

    // Number of moving average time periods supplied in the long group
    uint public numLongTimePeriods;

    // Number of moving average time periods supplied in the short group
    uint public numShortTimePeriods;

    // Full list of moving averages time periods: [L1, L2, ..., Lm, S1, S2, ..., Sn, 0]
    uint32[] public movingAverageTimePeriods;

    // Operator can update indicator parameters
    address public operator;

    /* ============ Constructor ============ */

    /**
     * @notice Initialize new MultipleMovingAverageCrossoverTrigger instance
     * @param _pool                    Address of the Uniswap V3 pool to be used as moving average oracle
     * @param _longTermTimePeriods     Long term moving average time periods in seconds
     * @param _shortTermTimePeriods    Short term moving average time periods in seconds
     * @param _uncertainIsBullish      Boolean to indicate whether indicator uncertain case is bullish or bearish
     * @param _operator                Address of operator who can update indicator parameters
     */
    constructor(
        IUniswapV3Pool _pool,
        uint32[] memory _longTermTimePeriods,
        uint32[] memory _shortTermTimePeriods,
        bool _uncertainIsBullish,
        address _operator
    )
        public 
    {
        pool = _pool;
        uncertainIsBullish = _uncertainIsBullish;
        operator = _operator;

        // Store number of moving averages in each group
        numLongTimePeriods = _longTermTimePeriods.length;
        numShortTimePeriods = _shortTermTimePeriods.length;

        // Collect all moving average durations and 0 in one array for UniswapV3 pool call
        for (uint i=0; i<numLongTimePeriods; i++) {
            movingAverageTimePeriods.push(_longTermTimePeriods[i]);
        }
        for (uint j=0; j<numShortTimePeriods; j++) {
            movingAverageTimePeriods.push(_shortTermTimePeriods[j]);
        }
        movingAverageTimePeriods.push(0);
    }

    /* ============ External ============ */

    /**
     * @notice Determines if Multiple Moving Average Crossover indicator is bullish at a given time
     *         Uses Uniswap V3 pool to collect time-weighted average prices in ticks
     *         Compares these to produce a signal
     * @return Boolean to represent if indicator is bullish
     */
    function isBullish() 
        external 
        view 
        returns (bool) 
    {
        // Gather cumulative tick values as of each `secondsAgos` from the current block timestamp 
        (int56[] memory tickCumulatives, ) = pool.observe(movingAverageTimePeriods);

        // Get minimum and maximum arithmetic mean tick from the long group
        int24 minLongMovingAverage = _getArithmeticMeanTick(tickCumulatives[0], tickCumulatives[numLongTimePeriods+numShortTimePeriods], movingAverageTimePeriods[0]);
        int24 maxLongMovingAverage = minLongMovingAverage;
        for (uint i=1; i<numLongTimePeriods; i++) 
        {
            int24 longMovingAverage = _getArithmeticMeanTick(tickCumulatives[i], tickCumulatives[numLongTimePeriods+numShortTimePeriods], movingAverageTimePeriods[i]);
            if (longMovingAverage < minLongMovingAverage) {
                minLongMovingAverage = longMovingAverage;
            }
            if (longMovingAverage > maxLongMovingAverage) {
                maxLongMovingAverage = longMovingAverage;
            }
        }

        // Get minimum and maximum arithmetic mean tick from the short group
        int24 minShortMovingAverage = _getArithmeticMeanTick(tickCumulatives[numLongTimePeriods], tickCumulatives[numLongTimePeriods+numShortTimePeriods], movingAverageTimePeriods[numLongTimePeriods]);
        int24 maxShortMovingAverage = minShortMovingAverage;
        for (uint j=numLongTimePeriods+1; j<numLongTimePeriods+numShortTimePeriods; j++) 
        {
            int24 shortMovingAverage = _getArithmeticMeanTick(tickCumulatives[j], tickCumulatives[numLongTimePeriods+numShortTimePeriods], movingAverageTimePeriods[j]);
            if (shortMovingAverage < minShortMovingAverage) {
                minShortMovingAverage = shortMovingAverage;
            }
            if (shortMovingAverage > maxShortMovingAverage) {
                maxShortMovingAverage = shortMovingAverage;
            }
        }

        // Compare short term and long term moving average groups and determine signal
        if (minShortMovingAverage > maxLongMovingAverage) {
            return true;
        } else if (maxShortMovingAverage < minLongMovingAverage) {
            return false;
        } else {
            return uncertainIsBullish;
        }
    }

    /**
     * OPERATOR ONLY: Update the operator address
     *
     * @param _newOperator           New operator address
     */
    function updateOperator(address _newOperator) external onlyOperator {
        emit OperatorChanged(operator, _newOperator);
        operator = _newOperator;
    }

    /**
     * OPERATOR ONLY: Update the Uniswap V3 pool to be used as moving average oracle
     *
     * @param _newPool           New pool address
     */
    function updatePool(IUniswapV3Pool _newPool) external onlyOperator {
        emit PoolChanged(pool, _newPool);
        pool = _newPool;
    }

    /**
     * OPERATOR ONLY: Update uncertain condition
     *
     * @param _newUncertainIsBullish New uncertain condition for indicator     
     */
    function updateUncertainIsBullish(bool _newUncertainIsBullish) external onlyOperator {
        emit UncertainIsBullishChanged(uncertainIsBullish, _newUncertainIsBullish);
        uncertainIsBullish = _newUncertainIsBullish;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Computes time-weighted average price in ticks from Uniswap V3 pool given tickCumulative and duration values
     * @param _historicalTickCumulative  Cumulative tick values as of each _duration seconds ago from the current block timestamp
     * @param _newTickCumulative         Cumulative tick values as of the current block timestamp
     * @param _duration                  Seconds ago from current block timestamp of _historicalTickCumulative
     * @return Time-weighted average price in ticks
     */
    function _getArithmeticMeanTick(
        int56 _historicalTickCumulative,
        int56 _newTickCumulative,
        uint32 _duration
    ) 
        internal 
        pure 
        returns (int24) 
    {
        return int24((_historicalTickCumulative - _newTickCumulative) / _duration);
    }

}