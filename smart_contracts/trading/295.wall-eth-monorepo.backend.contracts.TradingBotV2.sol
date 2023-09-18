// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// -- IMPORTS --
import {AutomationRegistryInterface, State, Config} from '@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol';
import {LinkTokenInterface} from '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import '@openzeppelin/contracts/utils/Counters.sol'; // Just a simple contracts that keep counts of how many times it's called
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

// -- INTERFACES --
interface KeeperRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
}

struct BotObj {
    address owner;
    uint256 orderInterval; // interval in seconds in which the bot swap 'amount' DAI for WETH
    uint256 orderSize;
    uint256 lastTimeStamp;
    uint256 counter; // count how many times we trade
    uint256 maxNumberOfOrders;
}

function stringToBytes32(string memory source) pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}

function bytes32ToString(bytes32 _bytes32) pure returns (string memory) {
    uint8 i = 0;
    while (i < 32 && _bytes32[i] != 0) {
        i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
        bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
}

// -- CONTRACTS --
contract TradingBotV2 is ReentrancyGuard, ChainlinkClient {
    using Counters for Counters.Counter;
    using Chainlink for Chainlink.Request;

    // -- CONSTANTS --
    uint24 public constant feeTier = 3000;
    uint8 public constant swapSlippage = 10; // 10%

    // -- VARIABLES --
    Counters.Counter private _botIdCounter; // Counter ID

    mapping(uint256 => BotObj) public botIdToBotObj;
    mapping(uint256 => uint256) public botIdToUpkeepId;
    mapping(bytes32 => uint256) public requestIdToBotId;

    LinkTokenInterface public immutable i_link;
    address public immutable registrar;
    AutomationRegistryInterface public immutable i_registry;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    ISwapRouter public immutable i_swapRouter;
    address public immutable i_stakedToken;
    address public immutable i_tradedToken;
    bytes32 public immutable i_stakedTokenSymbol;
    bytes32 public immutable i_tradedTokenSymbol;
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public tradingBalance;

    bytes32 public immutable i_getPriceJobId;
    uint256 public immutable i_getPriceFee;

    // for testing pourposes
    uint256 public price;
    string public lastError;

    // -- EVENTS --
    event FullfillPrice(bytes32 requestId, uint256 price);
    event SwapTokensForTokens(address sender, address tokenIn, address tokenOut, uint amountIn, uint amountOutMinimum);
    event ConcatenatedURL(string url);

    // -- ERRORS --
    error UpkeepNotNeeded(uint256 currentTimeStamp, uint256 lastTimeStamp);
    error AutoApproveDisabled();
    error NoCounterIDAssociated(bytes32 requestId);

    // -- CONSTRUCTOR --
    constructor(
        LinkTokenInterface _link,
        address _registrar,
        AutomationRegistryInterface _registry,
        ISwapRouter _swapRouter,
        address _stakedToken,
        address _tradedToken,
        address _chainlinkOracle,
        bytes32 _getPriceJobId,
        uint256 _getPriceFee
    ) {
        // GOERLI: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
        i_link = _link;
        // GOERLI: 0x9806cf6fBc89aBF286e8140C42174B94836e36F2
        registrar = _registrar;
        // GOERLI: 0x02777053d6764996e594c3E88AF1D58D5363a2e6
        i_registry = _registry;

        // Initialize Uniswap Router
        i_swapRouter = _swapRouter;

        // Set Tokens addresses
        i_stakedToken = _stakedToken;
        i_tradedToken = _tradedToken;
        i_stakedTokenSymbol = stringToBytes32(ERC20(_stakedToken).symbol());
        i_tradedTokenSymbol = stringToBytes32(ERC20(_tradedToken).symbol());

        // Chainlink Client stuff
        setChainlinkToken(address(_link));
        setChainlinkOracle(_chainlinkOracle);
        i_getPriceJobId = _getPriceJobId;
        i_getPriceFee = _getPriceFee;
    }

    // -- METHODS --
    function createNewBotInstance(
        address owner,
        uint256 orderInterval,
        uint256 orderSize,
        uint256 maxNumberOfOrders
    ) public returns (uint256) {
        uint256 botId = _botIdCounter.current();

        _botIdCounter.increment();

        // initialize an empty struct and then update it
        BotObj memory botObj;
        botObj.owner = owner;
        botObj.orderInterval = orderInterval;
        botObj.orderSize = orderSize;
        botObj.lastTimeStamp = block.timestamp;
        botObj.counter = 0;
        botObj.maxNumberOfOrders = maxNumberOfOrders;
        botIdToBotObj[botId] = botObj;

        return botId;
    }

    function registerNewAutomation(
        string memory name,
        uint32 gasLimit, // 999999
        uint96 fundingAmount, // 5 LINK
        uint256 orderInterval,
        uint256 orderSize
    ) public {
        require(stakingBalance[msg.sender] > 0, 'Your staking balance is empty! Deposit some DAI first');
        require(
            stakingBalance[msg.sender] >= orderSize,
            'Your orderSize is greater than your staking balance! Deposit more DAI'
        );

        uint256 maxNumberOfOrders = stakingBalance[msg.sender] / orderSize; // integer rounded down

        (State memory state, Config memory _c, address[] memory _k) = i_registry.getState();
        uint256 oldNonce = state.nonce;

        // Create a new bot instance and pass his Id as the checkData
        uint256 botId = createNewBotInstance(msg.sender, orderInterval, orderSize, maxNumberOfOrders);
        bytes memory checkData = abi.encodePacked(botId);
        bytes memory payload = abi.encode(
            name,
            '0x', // bytes calldata encryptedEmail
            address(this), // address upkeepContract
            gasLimit,
            address(msg.sender), // address adminAddress
            checkData,
            fundingAmount, // (N.B.) minimum 5.0 LINK
            0, // uint8 source
            address(this)
        );

        // Transfer Link and call the registrar
        i_link.transferAndCall(registrar, fundingAmount, bytes.concat(registerSig, payload));
        (state, _c, _k) = i_registry.getState();
        uint256 newNonce = state.nonce;

        if (newNonce == oldNonce + 1) {
            uint256 upkeepId = uint256(
                keccak256(abi.encodePacked(blockhash(block.number - 1), address(i_registry), uint32(oldNonce)))
            );
            // Set the upkeepID
            botIdToUpkeepId[botId] = upkeepId;
        } else {
            revert AutoApproveDisabled();
        }
    }

    function checkConditions(uint256 botId) internal view returns (bool upkeepNeeded) {
        bool isIntervalElapsed = (block.timestamp - botIdToBotObj[botId].lastTimeStamp) >
            botIdToBotObj[botId].orderInterval;

        upkeepNeeded = isIntervalElapsed;
    }

    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData) {
        // decode the checkData
        uint256 botId = abi.decode(checkData, (uint256));

        upkeepNeeded = checkConditions(botId);

        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external {
        // get the botId and botObj by decoding the checkData
        uint256 botId = abi.decode(performData, (uint256));
        BotObj storage botObj = botIdToBotObj[botId];

        // Check if this function is called by the checkUpKeep function or a possible attacker by re-checking the Conditions
        if (!checkConditions(botId)) {
            revert UpkeepNotNeeded(block.timestamp, botObj.lastTimeStamp);
        }

        // Re-Set the last time stamp and increment the counter
        botObj.lastTimeStamp = block.timestamp;
        botObj.counter = botObj.counter + 1;

        // TODO: BUY / SELL
        requestPriceAndSwapToken(botId);
    }

    function requestInflationData() public pure returns (uint256 yoyInflation) {
        // // Create a Chainlink request to retrieve API response, find the target data
        // Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        // return sendChainlinkRequest(req, fee);
        uint256 foo = 1;
        return foo;
    }

    function requestConsumerSentimentData() public pure returns (uint256 consumerSentiment) {
        // // Create a Chainlink request to retrieve API response, find the target data
        // Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        // return sendChainlinkRequest(req, fee);
        uint256 foo = 1;
        return foo;
    }

    function stake(uint256 stakingAmount) public {
        // stakingAmount must be > 0
        require(stakingAmount > 0, 'amount should be > 0');

        // Transfer the specified amount of DAI to this contract
        TransferHelper.safeTransferFrom(i_stakedToken, msg.sender, address(this), stakingAmount);

        // Update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + stakingAmount;
    }

    function unstake() public nonReentrant {
        uint256 balance = stakingBalance[msg.sender];

        // Balance should be > 0
        require(balance > 0, 'Your balance is 0, you have nothing to withdraw');

        // Reset staking balance
        stakingBalance[msg.sender] = 0;

        // Transfer Dai tokens to the sender
        TransferHelper.safeTransfer(i_stakedToken, msg.sender, balance);
    }

    function swapTokensForTokens(
        address sender,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMinimum
    ) public returns (uint256 amountOut) {
        emit SwapTokensForTokens(sender, tokenIn, tokenOut, amountIn, amountOutMinimum);

        // The User staked tokens balance must me greater or equal of the amountIn
        if (stakingBalance[sender] < amountIn) {
            // require(stakingBalance[sender] >= amountIn, 'The sender does not have staked enough DAI');
            lastError = 'The User does not have staked enough WETH';
            return 0;
        }

        // The Contract staked tokens balance must me greater or equal of the amountIn
        if (ERC20(i_stakedToken).balanceOf(address(this)) < amountIn) {
            // require(stakingBalance[sender] >= amountIn, 'The sender does not have staked enough DAI');
            lastError = 'The Contract does not have enough WETH';
            return 0;
        }

        // Approve the router to spend DAI
        TransferHelper.safeApprove(tokenIn, address(i_swapRouter), amountIn);

        // Create the params that will be used to execute the swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: feeTier,
            recipient: sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        // The call to `exactInputSingle` executes the swap
        amountOut = i_swapRouter.exactInputSingle(params);

        // Update user balance
        stakingBalance[sender] = stakingBalance[sender] - amountIn;
        tradingBalance[sender] = tradingBalance[sender] + amountOut;

        return amountOut;
    }

    function requestPriceAndSwapToken(uint256 botId) public returns (bytes32 requestId) {
        string memory fsyms = bytes32ToString(i_stakedTokenSymbol);
        string memory tsyms = bytes32ToString(i_tradedTokenSymbol);

        Chainlink.Request memory req = buildChainlinkRequest(i_getPriceJobId, address(this), this.fulfill.selector);

        // Set the URL to perform the GET request on
        req.add(
            'get',
            string(
                abi.encodePacked(
                    'https://min-api.cryptocompare.com/data/pricemultifull?fsyms=',
                    fsyms,
                    '&tsyms=',
                    tsyms,
                    '&extraParams=Wall-ETH'
                )
            )
        );

        // Set the path to find the desired data in the API response ('RAW,ETH,USD,PRICE')
        req.add('path', string(abi.encodePacked('RAW,', fsyms, ',', tsyms, ',PRICE')));

        // Multiply the result by 10**18 to remove decimals
        req.addInt('times', int256(10**18));

        // Send the request and save the 'counterId' associated with the 'requestId' returned by the send
        requestId = sendChainlinkRequest(req, i_getPriceFee);
        requestIdToBotId[requestId] = botId;
    }

    function fulfill(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId) {
        // Emit and Event and set the price
        emit FullfillPrice(_requestId, _price);
        price = _price;

        // Get the botId & the botObj associated with this price request
        uint256 botId = requestIdToBotId[_requestId];
        BotObj memory botObj = botIdToBotObj[botId];

        // If the botObj is empty throw an error
        if (botObj.orderSize == 0) {
            // revert NoCounterIDAssociated(_requestId);
            lastError = 'NoCounterIDAssociated(_requestId)';
            return;
        }

        // Calculate the minimum amount
        uint amountOut = (_price * botObj.orderSize) / 10**18;
        uint amountOutMinimum = amountOut - (amountOut * swapSlippage) / 100;

        // Swap the tokens
        swapTokensForTokens(
            botObj.owner,
            i_stakedToken,
            i_tradedToken,
            botObj.orderSize,
            0 // we use 0 because in the testnet the price of the tokens doesn't actually reflect the real market
        );
    }
}
