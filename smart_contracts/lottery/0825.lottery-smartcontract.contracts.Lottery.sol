//  Lottery contract
// Enter the lottery (paying some amount)
// Pick a random winnder (verifiably random)
// winner to be selected every X minutes => completely automated
// Chainlink Oracle -> Randomness, Automated Execution (Chainlink keeper)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Lottery__Not_Enough_ETH_Entered();
error Lottery__TransferFailed();
error Lottery__Not_Open();
error Lottery__UpKeep_Not_Needed(
    uint256 balance,
    uint256 numPlayers,
    uint256 lotteryState
);

/**
 * @title A sample Lottery Contract
 * @author Saikrishna Sangishetty
 * @notice This contract is for creating an untamperable decentralized smart contract lottery system
 * @dev This implements Chainlink VRF V2 and Chainlink Keepers
 */
abstract contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /**Type declarations */
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    // State Variables
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    // Lottery variables
    address private s_recentWinner;
    LotteryState private s_lotteryState;

    // events
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    // functions
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

    /**
     * @notice reverts if sent amount is less than valid entrance fee
     * @notice reverts if lottery is not in "open" state
     * @dev adds player to players storage
     * @dev emits RaffleEnter event on successful entry to lottery
     *
     */
    function enterLottery() public payable {
        // require msg.value > i_entranceFee

        if (msg.value < i_entranceFee) {
            revert Lottery__Not_Enough_ETH_Entered();
        }

        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__Not_Open();
        }

        s_players.push(payable(msg.sender));

        // emit and event when we update a dynamic array or mapping
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev This is the function that the chainlink keeper nodes calls
     * they look for the "upkeepNeeded" return true
     * The following should be true in order to return true
     * 1. Our time interval should have passed
     * 2. The lottery should have at least 1 player, and have some ETH
     * 3. Our subscription is funded with LINK
     * 4. The lottery should be in an "open" state
     */
    function checkUpkeep(
        bytes memory /**checkData */
    )
        public
        view
        override
        returns (bool upKeepNeeded, bytes memory /**performData */)
    {
        bool isOpen = (LotteryState.OPEN == s_lotteryState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;

        upKeepNeeded = isOpen && timePassed && hasPlayers && hasBalance;
        //
    }

    // external means wont be used by this contract
    function performUpkeep(bytes calldata /**performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Lottery__UpKeep_Not_Needed(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }
        // Will revert if subscription is not set and funded.
        s_lotteryState = LotteryState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /**requestId */,
        uint256[] memory randomWords
    ) internal override {
        // 0th element as it will have only one random word based on config "NUM_WORDS" sent in requestRandomWords
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = s_recentWinner;
        s_lotteryState = LotteryState.OPEN;
        s_players = new address payable[](0); // reset players
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");

        if (!success) {
            revert Lottery__TransferFailed();
        }

        emit WinnerPicked(recentWinner);
    }

    // view/pure functions
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimestamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }
}
