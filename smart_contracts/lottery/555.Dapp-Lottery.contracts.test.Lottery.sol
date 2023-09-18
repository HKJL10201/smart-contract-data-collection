// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**
 * @author Stefania Pozzi
 * @notice This contract accepts an user buying a ticket.
 * Then, every 30 seconds
 * it selects a random winner
 * @dev Chainlink VRF V2, Keepers
 * */

contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Types */
    enum LotteryState {
        OPEN,
        PROCESSING
    }

    /* State variables */
    uint256 private immutable i_entranceFee; //why not immutable but storage
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_lastBlockTimestamp;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint256 private immutable i_interval;

    /* Contract Variables */
    address private s_winner;
    LotteryState private s_lotteryState;

    /* Errors and Events */
    error Lottery__NotEnoughETHToBuyATicket();
    error Lottery__TransferFailed();
    error Lottery__StateIsNotOpen();
    error Lottery__PerformUpkeepNotNeeded(uint256 balance, uint256 numPlayers, uint256 state);

    event LotteryEnter(address indexed player);
    event LotteryRequestedWinner(uint256 indexed requestId);
    event LotteryWinnerPicked(address indexed winner);
    event UpkeepNeeded(bool isOpen,bool timeHasPassed,bool hasPlayers,bool hasBalance);

    constructor(
        address vrfCoordinatorV2, //external contract: deploying mock
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
        s_lotteryState = LotteryState(0); //or LotteryState.OPEN
        s_lastBlockTimestamp = block.timestamp;
        i_interval = interval;
    }

    function enterLottery() public payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughETHToBuyATicket();
        }
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__StateIsNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit LotteryEnter(msg.sender);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_players = new address payable[](0);
        s_lastBlockTimestamp = block.timestamp;
        s_lotteryState = LotteryState.OPEN;
        s_winner = winner;

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
        emit LotteryWinnerPicked(winner);
    }

    /**
     * @dev Chainlink keeper implementation
     * Chainlink nodes checks if upkeepNeeded is true
     * 1. Time is passed
     * 2. Lottery is not computating
     * 3. More than 1 player and Lottery contract must have positive balance
     * 4. LINK in subscription balance for VRF
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = LotteryState.OPEN == s_lotteryState;
        bool timeHasPassed = (block.timestamp - s_lastBlockTimestamp) > i_interval;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = isOpen && timeHasPassed && hasPlayers && hasBalance;
        emit UpkeepNeeded(isOpen,timeHasPassed, hasPlayers, hasBalance);

    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__PerformUpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }
        s_lotteryState = LotteryState.PROCESSING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            uint32(i_callbackGasLimit),
            NUM_WORDS
        );
        emit LotteryRequestedWinner(requestId);
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayers(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_winner;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getLatestTimestamp() public view returns (uint256) {
        return s_lastBlockTimestamp;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATION;
    }

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}
