// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/* Imports */
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/* Error codes */
error Lottery__InsufficientEntranceFee();
error Lottery__TransferFailed();
error Lottery__NotOpen();
error Lottery_UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 lotteryState
);

/** @title Lottery Contract
 * @author Aditya Padekar
 * @notice This contract is for creating a lottery and picking a winner faily
 * @dev This contract implements the Chainlink VRF version 2 in order to implement true randomness
 */
contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Types */
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    /* State Variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;

    /* Randomness VRF V2 Variables */
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    /* Lottery Variables */
    address private s_recentWinner;
    LotteryState private s_lotteryState; 
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /* Events */
    event LotteryEnter(address indexed player);
    event LotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /** Constructor
     * @param  entranceFee is the minimum amount the participant should pay to
     * enter in the lottery - set by the creater of the lotter
     * @dev it sets the minimun entry fee depending upon the parameter passed
     */
    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    /** Participate in Lottey
     * @dev this function allow players to participate in the lottery
     * with required constraints
     */
    function enterLottery() public payable {
        if (msg.value < i_entranceFee)
            revert Lottery__InsufficientEntranceFee();

        if (s_lotteryState != LotteryState.OPEN) revert Lottery__NotOpen();

        s_players.push(payable(msg.sender));
        emit  LotteryEnter(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = (LotteryState.OPEN == s_lotteryState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = (address(this).balance > 0);
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    // function performUpkeep(bytes calldata performData) external override {}

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded)
            revert Lottery_UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );

        s_lotteryState = LotteryState.CALCULATING;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit LotteryWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        s_lotteryState = LotteryState.OPEN;

        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) revert Lottery__TransferFailed();

        emit WinnerPicked(recentWinner);
    }

    function getLotteryState() public view returns (LotteryState){
        return s_lotteryState;
    }

    function getNumWords() public pure returns(uint256){
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns(uint256){
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }
    
    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }
    
    function getLastTimeStamp() public view returns(uint256){
        return s_lastTimeStamp;
    }
    
    function getInterval() public view returns(uint256){
        return i_interval;
    }
    
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getNumberOfPlayers() public view returns(uint256){
        return s_players.length;
    }

}
