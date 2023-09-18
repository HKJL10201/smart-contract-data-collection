// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@chainlink/contracts/src/v0.8/AutomationCompatible.sol';
import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract TradingBot is AutomationCompatibleInterface, ChainlinkClient, ReentrancyGuard {
    using Chainlink for Chainlink.Request;

    // -- CONSTANTS --
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint24 public constant feeTier = 3000;

    // -- VARIABLES --
    uint private s_counter; // just temporary
    uint private s_interval; // after how many seconds pull the data from Truflation
    uint private s_lastTimeStamp;
    uint256 private immutable i_truflationOracleFee;
    bytes32 private immutable i_truflationOracleJobId;
    ISwapRouter public immutable i_swapRouter;
    mapping(address => uint256) public s_stakingBalanceDAI;
    mapping(address => uint256) public s_dcaValue;

    // -- EVENTS --
    event RequestInflation(bytes32 indexed requestId, uint256 inflation);

    // -- ERRORS --
    error UpkeepNotNeeded(uint timePassed);

    // -- CONSTRUCTOR --
    constructor(
        uint256 interval,
        uint256 truflationOracleFee,
        bytes32 truflationOracleJobId,
        ISwapRouter swapRouter
    ) {
        // Initialize truflation oracle
        i_truflationOracleFee = truflationOracleFee;
        i_truflationOracleJobId = truflationOracleJobId;

        // Initialize Uniswap Router
        i_swapRouter = swapRouter;

        s_counter = 0;
    }

    // -- METHODS --
    function checkConditions() private view returns (bool) {
        bool isIntervalElapsed = (block.timestamp - s_lastTimeStamp) > s_interval;

        // If interval seconds are elapsed we pull truflation data and check the market conditions, else return false
        if (isIntervalElapsed) {
            // Retrieve truflation data
            uint256 yoyInflation = requestInflationData();
            uint256 consumerSentiment = requestConsumerSentimentData();

            // - Delta >= 1 --> make a trade
            // - Delta < 1 ---> don't trade
            return (yoyInflation * consumerSentiment >= 1);
        } else {
            return (false);
        }
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = checkConditions();

        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        // Check if this function is called by the checkUpKeep function or a possible attacker by re-checking the Conditions
        if (!checkConditions()) {
            revert UpkeepNotNeeded(block.timestamp - s_lastTimeStamp);
        }

        s_lastTimeStamp = block.timestamp;

        s_counter = s_counter + 1;

        // TODO: BUY / SELL
    }

    function setupBot(uint256 dcaAmount, uint dcaInterval) public {
        // Initialize chainlink automation
        s_interval = dcaInterval;
        s_lastTimeStamp = block.timestamp;
    }

    function stakeDAI(uint256 amount, uint256 dcaValue) public {
        // amount and dcaValue must be > 0
        require(amount > 0, 'amount should be > 0');
        require(dcaValue > 0, 'dcaValue should be > 0');

        // Transfer the specified amount of DAI to this contract
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amount);

        // Update staking balance and dcaValue
        s_stakingBalanceDAI[msg.sender] = s_stakingBalanceDAI[msg.sender] + amount;
        s_dcaValue[msg.sender] = dcaValue;
    }

    function unstakeDAI() public nonReentrant {
        uint256 balance = s_stakingBalanceDAI[msg.sender];

        // Balance should be > 0
        require(balance > 0, 'Your balance is 0, you have nothing to withdraw');

        // Reset staking balance
        s_stakingBalanceDAI[msg.sender] = 0;

        // Transfer Dai tokens to the sender
        TransferHelper.safeTransfer(DAI, msg.sender, balance);
    }

    function swapDAIForWETH(uint amountIn) external returns (uint256 amountOut) {
        // Staked DAI must be greater tha amountIn
        require(s_stakingBalanceDAI[msg.sender] > amountIn, 'The sender does not have staked enough DAI');

        // Approve the router to spend DAI
        TransferHelper.safeApprove(DAI, address(i_swapRouter), amountIn);

        // Create the params that will be used to execute the swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: DAI,
            tokenOut: WETH9,
            fee: feeTier,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // The call to `exactInputSingle` executes the swap
        amountOut = i_swapRouter.exactInputSingle(params);

        // Update staking balance
        s_stakingBalanceDAI[msg.sender] = s_stakingBalanceDAI[msg.sender] - amountIn;

        return amountOut;
    }

    // Create a Chainlink request to retrieve API response, find the target data
    function requestInflationData() public pure returns (uint256 yoyInflation) {
        // Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        // return sendChainlinkRequest(req, fee);
        uint256 foo = 1;
        return foo;
    }

    // Create a Chainlink request to retrieve API response, find the target data
    function requestConsumerSentimentData() public pure returns (uint256 consumerSentiment) {
        // Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        // return sendChainlinkRequest(req, fee);
        uint256 foo = 1;
        return foo;
    }

    // -- GETTERS --
    function getCounter() public view returns (uint) {
        return s_counter;
    }

    function getInterval() public view returns (uint) {
        return s_interval;
    }

    function getTruflationOracleFee() public view returns (uint256) {
        return i_truflationOracleFee;
    }

    function getTruflationOracleJobId() public view returns (bytes32) {
        return i_truflationOracleJobId;
    }

    function getLastTimeStamp() public view returns (uint) {
        return s_lastTimeStamp;
    }

    function getBalanceOf(address staker) public view returns (uint256) {
        return s_stakingBalanceDAI[staker];
    }
}
