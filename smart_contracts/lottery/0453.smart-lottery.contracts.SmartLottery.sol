// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error SmartLottery__LotteryNotOpen();
error SmartLottery__NotEnoughFunds();
error SmartLottery__PlayerAlreadyInLottery();
error SmartLottery__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 lotteryState
);
error SmartLottery__NoPendingRewards();
error SmartLottery__ExternalCallFailed();

/**
 * @title SmartLottery
 * @author jrmunchkin
 * @notice This contract creates a simple lottery which will picked a random winner once the lottery end.
 * The player must pay entrance fee to play the lottery, the winner win all the pot.
 * @dev The constructor takes an interval (time of duration of the lottery) and and usd entrance fee (entrance fee in dollars).
 * This contract implements Chainlink Keeper to trigger when the lottery must end.
 * This contract implements Chainlink VRF to pick a random winner when the lottery ends.
 * This contract also implements the Chainlink price feed to know the entrance fee value in ETH.
 */
contract SmartLottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
    enum LotteryState {
        OPEN,
        CALCULATE_WINNER
    }

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    AggregatorV3Interface private immutable i_ethUsdPriceFeed;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_usdEntranceFee;
    uint256 private immutable i_interval;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    LotteryState private s_lotteryState;
    uint256 private s_lotteryNumber;
    address payable[] private s_players;
    uint256 private s_startTimestamp;
    mapping(uint256 => uint256) private s_lotteryBalance;
    mapping(uint256 => address) private s_lotteryWinners;
    mapping(address => uint256) private s_rewardsBalance;

    event StartLottery(uint256 indexed lotteryNumber, uint256 startTime);
    event EnterLottery(uint256 indexed lotteryNumber, address indexed player);
    event RequestLotteryWinner(
        uint256 indexed lotteryNumber,
        uint256 indexed requestId
    );
    event WinnerLotteryPicked(
        uint256 indexed lotteryNumber,
        address indexed winner
    );
    event ClaimLotteryRewards(address indexed winner, uint256 amount);

    /**
     * @notice contructor
     * @param _vrfCoordinatorV2 VRF Coordinator contract address
     * @param _subscriptionId Subscription Id of Chainlink VRF
     * @param _gasLane Gas lane of Chainlink VRF
     * @param _callbackGasLimit Callback gas limit of Chainlink VRF
     * @param _ethUsdPriceFeed Price feed address ETH to USD
     * @param _usdEntranceFee Entrance fee value in dollars
     * @param _interval Duration of the lottery
     */
    constructor(
        address _vrfCoordinatorV2,
        uint64 _subscriptionId,
        bytes32 _gasLane,
        uint32 _callbackGasLimit,
        address _ethUsdPriceFeed,
        uint256 _usdEntranceFee,
        uint256 _interval
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        i_subscriptionId = _subscriptionId;
        i_gasLane = _gasLane;
        i_callbackGasLimit = _callbackGasLimit;
        i_ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        i_usdEntranceFee = _usdEntranceFee * (10 ** 18);
        i_interval = _interval;
        s_lotteryNumber = 1;
        s_lotteryState = LotteryState.OPEN;
    }

    /**
     * @notice Allow user to enter the lottery by paying entrance fee
     * @dev When the first player enter the lottery the duration start
     * emit an event EnterLottery when player enter the lottery
     * emit an event StartLottery the lottery duration start
     */
    function enterLottery() external payable {
        if (s_lotteryState != LotteryState.OPEN)
            revert SmartLottery__LotteryNotOpen();
        if (msg.value < getEntranceFee()) revert SmartLottery__NotEnoughFunds();
        if (isPlayerAlreadyInLottery(msg.sender))
            revert SmartLottery__PlayerAlreadyInLottery();
        s_lotteryBalance[s_lotteryNumber] += msg.value;
        s_players.push(payable(msg.sender));
        if (s_players.length == 1) {
            s_startTimestamp = block.timestamp;
            emit StartLottery(s_lotteryNumber, s_startTimestamp);
        }
        emit EnterLottery(s_lotteryNumber, msg.sender);
    }

    /**
     * @notice Chainlink checkUpkeep which will check if lottery must end
     * @return upkeepNeeded boolean to know if Chainlink must perform upkeep
     * @dev Lottery end when all this assertions are true :
     * The lottery is open
     * The lottery have at least one player
     * The lottery have some balance
     * The lottery duration is over
     */
    function checkUpkeep(
        bytes memory /* _checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = s_lotteryState == LotteryState.OPEN;
        bool timePassed = ((block.timestamp - s_startTimestamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = s_lotteryBalance[s_lotteryNumber] > 0;
        upkeepNeeded = isOpen && timePassed && hasPlayers && hasBalance;
        return (upkeepNeeded, "0x0");
    }

    /**
     * @notice Chainlink performUpkeep which will end the lottery
     * @dev This function is call if upkeepNeeded of checkUpkeep is true
     * Call Chainlink VRF to request a random winner
     * emit an event RequestLotteryWinner when request winner is called
     */
    function performUpkeep(
        bytes calldata /* _performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert SmartLottery__UpkeepNotNeeded(
                s_lotteryBalance[s_lotteryNumber],
                s_players.length,
                uint256(s_lotteryState)
            );
        }
        s_lotteryState = LotteryState.CALCULATE_WINNER;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestLotteryWinner(s_lotteryNumber, requestId);
    }

    /**
     * @notice Picked a random winner and restart lottery
     * @dev Call by the Chainlink VRF after requesting a random winner
     * emit an event WinnerLotteryPicked when random winner has been picked
     */
    function fulfillRandomWords(
        uint256 /*_requestId*/,
        uint256[] memory _randomWords
    ) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        uint256 actualLotteryNumber = s_lotteryNumber;
        address winner = s_players[indexOfWinner];
        s_lotteryWinners[actualLotteryNumber] = winner;
        s_players = new address payable[](0);
        s_lotteryState = LotteryState.OPEN;
        s_lotteryNumber++;
        s_rewardsBalance[winner] =
            s_rewardsBalance[winner] +
            s_lotteryBalance[actualLotteryNumber];
        emit WinnerLotteryPicked(
            actualLotteryNumber,
            s_lotteryWinners[actualLotteryNumber]
        );
    }

    /**
     * @notice Allow user to claim his lottery rewards
     * emit an event ClaimLotteryRewards when user claimed his rewards
     */
    function claimRewards() external {
        if (s_rewardsBalance[msg.sender] <= 0)
            revert SmartLottery__NoPendingRewards();
        uint256 toTransfer = s_rewardsBalance[msg.sender];
        s_rewardsBalance[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: toTransfer}("");
        if (!success) revert SmartLottery__ExternalCallFailed();
        emit ClaimLotteryRewards(msg.sender, toTransfer);
    }

    /**
     * @notice Check if the user already play the lottery
     * @param _user address of the user
     * @return isAllowed true if already play, false ether
     */
    function isPlayerAlreadyInLottery(
        address _user
    ) public view returns (bool) {
        for (
            uint256 playersIndex = 0;
            playersIndex < s_players.length;
            playersIndex++
        ) {
            if (s_players[playersIndex] == _user) return true;
        }
        return false;
    }

    /**
     * @notice Get entrance fee to participate to the lottery
     * @return entranceFee Entrance fee in ETH
     * @dev Implements Chainlink price feed
     */
    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = i_ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10 ** 10;
        return (i_usdEntranceFee * 10 ** 18) / adjustedPrice;
    }

    /**
     * @notice Get entrance fee in dollars to participate to the lottery
     * @return usdEntranceFee Entrance fee in dollars
     */
    function getUsdEntranceFee() external view returns (uint256) {
        return i_usdEntranceFee;
    }

    /**
     * @notice Get duration of the lottery
     * @return interval Duration of the lottery
     */
    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    /**
     * @notice Get actual lottery number
     * @return lotteryNumber Actual lottery number
     */
    function getActualLotteryNumber() external view returns (uint256) {
        return s_lotteryNumber;
    }

    /**
     * @notice Get the state of the lottery
     * @return lotteryState Lottery state
     */
    function getLotteryState() external view returns (LotteryState) {
        return s_lotteryState;
    }

    /**
     * @notice Get player address with index
     * @param _index Index of player
     * @return player Player address
     */
    function getPlayer(uint256 _index) external view returns (address) {
        return s_players[_index];
    }

    /**
     * @notice Get the number of players of the lottery
     * @return numPlayers Number of players
     */
    function getNumberOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    /**
     * @notice Get the timestamp when the lottery start
     * @return startTimestamp Start timestamp
     */
    function getStartTimestamp() external view returns (uint256) {
        return s_startTimestamp;
    }

    /**
     * @notice Get the value of rewards of the actual lottery
     * @return lotteryBalance Lottery Balance
     */
    function getActualLotteryBalance() external view returns (uint256) {
        return s_lotteryBalance[s_lotteryNumber];
    }

    /**
     * @notice Get the value of rewards of a specific lottery
     * @param _lotteryNumber The number of the lottery
     * @return lotteryBalance Lottery Balance
     */
    function getLotteryBalance(
        uint256 _lotteryNumber
    ) external view returns (uint256) {
        return s_lotteryBalance[_lotteryNumber];
    }

    /**
     * @notice Get the winner of a specific lottery
     * @param _lotteryNumber The number of the lottery
     * @return lotteryWinner Lottery winner
     */
    function getWinner(uint256 _lotteryNumber) external view returns (address) {
        return s_lotteryWinners[_lotteryNumber];
    }

    /**
     * @notice Get the user pending rewards of his winning lotteries
     * @param _user address of the user
     * @return rewardsBalance Rewards balance
     */
    function getUserRewardsBalance(
        address _user
    ) external view returns (uint256) {
        return s_rewardsBalance[_user];
    }
}
