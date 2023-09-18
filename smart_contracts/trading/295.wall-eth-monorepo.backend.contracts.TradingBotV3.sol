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
import './TruflationClient.sol';

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
contract TradingBotV3 is ReentrancyGuard, ChainlinkClient {
    using Counters for Counters.Counter;
    using Chainlink for Chainlink.Request;

    // -- CONSTANTS --
    uint24 public constant feeTier = 3000;
    uint8 public constant swapSlippage = 10; // 10%
    uint256 public constant cacheInterval = 60 * 60 * 24; // 1 day

    // -- VARIABLES --
    Counters.Counter private _botIdCounter; // Counter ID

    mapping(uint256 => BotObj) public botIdToBotObj;
    mapping(uint256 => uint256) public botIdToUpkeepId;
    mapping(bytes32 => uint256) public requestIdToBotId;

    LinkTokenInterface public immutable i_link;
    address public immutable i_registrar;
    AutomationRegistryInterface public immutable i_registry;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    ISwapRouter public immutable i_swapRouter;
    address public immutable i_stakedToken;
    address public immutable i_tradedToken;
    bytes32 public immutable i_stakedTokenSymbol;
    bytes32 public immutable i_tradedTokenSymbol;
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public tradingBalance;
    mapping(address => uint256) public fundingBalance;

    bytes32 public immutable i_getPriceJobId;
    uint256 public immutable i_getPriceFee;

    address public i_truflationOracle;

    // -- EVENTS --
    event FullfillPrice(bytes32 requestId, uint256 price);
    event SwapTokensForTokens(address sender, uint amountIn, uint amountOutMinimum);
    event ConcatenatedURL(string url);
    event TradeOccured(address indexed receiver, uint256 amountIn, uint256 amountOut);

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
        uint256 _getPriceFee,
        address _truflationOracle
    ) {
        // GOERLI: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
        i_link = _link;
        // GOERLI: 0x9806cf6fBc89aBF286e8140C42174B94836e36F2
        i_registrar = _registrar;
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

        // Truflation contract
        i_truflationOracle = _truflationOracle;
    }

    // -- METHODS --
    function createNewBotInstance(
        address owner,
        uint256 orderInterval,
        uint256 orderSize
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
        require(fundingAmount >= 5000000000000000000, 'minimum fundingAmount is 5 LINK');
        require(orderInterval >= 60, 'minimum orderInterval is 60 seconds');
        require(orderSize >= 100000000000000, 'minimum orderSize is 0,0001 stakedToken');
        require(fundingBalance[msg.sender] >= fundingAmount, 'your funding balance is < of your fundingAmount');

        (State memory state, Config memory _c, address[] memory _k) = i_registry.getState();
        uint256 oldNonce = state.nonce;

        // Create a new bot instance and pass his Id as the checkData
        uint256 botId = createNewBotInstance(msg.sender, orderInterval, orderSize);
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

        // Update the funds balance
        fundingBalance[msg.sender] = fundingBalance[msg.sender] - fundingAmount;

        // Transfer Link and call the registrar
        i_link.transferAndCall(i_registrar, fundingAmount, bytes.concat(registerSig, payload));
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
        BotObj memory botObj = botIdToBotObj[botId];

        bool isIntervalElapsed = (block.timestamp - botObj.lastTimeStamp) > botObj.orderInterval;
        bool isUserStakingBalanceZero = stakingBalance[botObj.owner] == 0;

        upkeepNeeded = isIntervalElapsed && !isUserStakingBalanceZero;
    }

    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData) {
        // decode the checkData and get the botId
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

        // If the inflation is older update it
        if ((block.timestamp - TruflationClient(i_truflationOracle).lastTimeStamp()) > cacheInterval) {
            // approve truflation oracle to spend link
            ERC20(address(i_link)).approve(i_truflationOracle, TruflationClient(i_truflationOracle).fee());

            // Update the funds balance
            fundingBalance[botObj.owner] = fundingBalance[botObj.owner] - TruflationClient(i_truflationOracle).fee();

            // transfer and request inflation
            TruflationClient(i_truflationOracle).transferAndRequestInflation();
        }

        // Update the funds balance
        fundingBalance[botObj.owner] = fundingBalance[botObj.owner] - i_getPriceFee;

        // Trade!
        requestPriceAndSwapToken(botId);
    }

    function stake(uint256 stakingAmount) public {
        require(stakingAmount > 0, 'amount should be > 0');

        // Transfer the specified amount of DAI to this contract
        TransferHelper.safeTransferFrom(i_stakedToken, msg.sender, address(this), stakingAmount);

        // Update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + stakingAmount;
    }

    function unstake() public nonReentrant {
        uint256 balance = stakingBalance[msg.sender];

        // Balance should be > 0
        require(balance > 0, 'Your stake balance is 0, you have nothing to withdraw');

        // Reset staking balance
        stakingBalance[msg.sender] = 0;

        // Transfer Dai tokens to the sender
        TransferHelper.safeTransfer(i_stakedToken, msg.sender, balance);
    }

    function fund(uint256 fundingAmount) public {
        require(fundingAmount > 0, 'amount should be > 0');

        // Transfer the specified amount of LINK to this contract
        TransferHelper.safeTransferFrom(address(i_link), msg.sender, address(this), fundingAmount);

        // Update staking balance
        fundingBalance[msg.sender] = fundingBalance[msg.sender] + fundingAmount;
    }

    function withdrawFunds() public nonReentrant {
        uint256 balance = fundingBalance[msg.sender];

        // Balance should be > 0
        require(balance > 0, 'Your funding balance is 0, you have nothing to withdraw');

        // Reset staking balance
        fundingBalance[msg.sender] = 0;

        // Transfer Dai tokens to the sender
        TransferHelper.safeTransfer(address(i_link), msg.sender, balance);
    }

    function swapTokensForTokens(
        address receiver,
        uint amountIn,
        uint amountOutMinimum
    ) public {
        emit SwapTokensForTokens(receiver, amountIn, amountOutMinimum);

        // Approve the router to spend DAI
        TransferHelper.safeApprove(i_stakedToken, address(i_swapRouter), amountIn);

        // Create the params that will be used to execute the swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: i_stakedToken,
            tokenOut: i_tradedToken,
            fee: feeTier,
            recipient: receiver,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        // The call to `exactInputSingle` executes the swap
        uint256 amountOut = i_swapRouter.exactInputSingle(params);

        // Update user balance
        stakingBalance[receiver] = stakingBalance[receiver] - amountIn;
        tradingBalance[receiver] = tradingBalance[receiver] + amountOut;

        emit TradeOccured(receiver, amountIn, amountOut);
    }

    function requestPriceAndSwapToken(uint256 botId) public returns (bytes32 requestId) {
        //string memory fsyms = bytes32ToString(i_stakedTokenSymbol); // real net
        string memory fsyms = 'MATIC'; // mumbai net :(
        string memory tsyms = bytes32ToString(i_tradedTokenSymbol);

        Chainlink.Request memory req = buildChainlinkRequest(
            i_getPriceJobId,
            address(this),
            this.fulfillPrice.selector
        );

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

    function fulfillPrice(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId) {
        // Emit and Event and set the price
        emit FullfillPrice(_requestId, _price);

        // Get the botId & the botObj associated with this price request
        uint256 botId = requestIdToBotId[_requestId];
        BotObj memory botObj = botIdToBotObj[botId];

        // If the botObj is empty throw an error
        if (botObj.orderSize == 0) {
            revert NoCounterIDAssociated(_requestId);
        }

        // Calculate the minimum amount
        uint amountOut = (_price * botObj.orderSize) / 10**18;
        uint amountOutMinimum = amountOut - (amountOut * swapSlippage) / 100;

        // Calculate order amount adjusted by the inflation (divide by 10^20 because it's a percentage)
        int256 inflation = TruflationClient(i_truflationOracle).inflation();
        uint256 orderAmount;
        if (inflation > 0 && inflation < 50000000000000000000) /* positive and < 50% */
        {
            orderAmount = botObj.orderSize + ((botObj.orderSize * uint256(inflation)) / 10**20);
        } else if (inflation < 0 && inflation > -50000000000000000000) /* negative and > -50% */
        {
            orderAmount = botObj.orderSize - ((botObj.orderSize * uint256(inflation)) / 10**20);
        }
        /* equal to zero or +-50% */
        else {
            orderAmount = botObj.orderSize;
        }

        // If the user has insufficient funds we use the maximum amount possible
        if (stakingBalance[botObj.owner] < orderAmount) {
            orderAmount = stakingBalance[botObj.owner];
        }

        // Swap the tokens
        // we use 0 as 'amountOutMinimum' because in the testnet the price of the tokens doesn't actually reflect the real market
        swapTokensForTokens(botObj.owner, orderAmount, 0);
    }
}
