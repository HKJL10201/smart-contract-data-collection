// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

error Lottery__InsufficientFunds();
error Lottery__TransactionFailed();
error Lottery__NotOpen();
error Lottery__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 lotteryState
);

contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
    enum State {
        OPEN,
        CALCULATING
    }

    /* State variables */
    VRFCoordinatorV2Interface private immutable i_coordinator;
    uint256 private immutable i_entranceFee;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    //if one of the players wins we need to pay them
    address payable[] private players;

    /* Lottery variables */
    address s_recentWinner;
    State private s_lotteryState;
    uint256 private s_lastBlockTimestamp;
    uint256 private immutable i_interval;

    /* Events */
    event LotteryEnter(address indexed player);
    event RequestedLotteryWinner(uint256 requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinator,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_entranceFee = entranceFee;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lotteryState = State.OPEN;
        s_lastBlockTimestamp = block.timestamp;
        i_interval = interval;
    }

    function enterLottery() public payable {
        if (msg.value < i_entranceFee) revert Lottery__InsufficientFunds();
        if (s_lotteryState != State.OPEN) revert Lottery__NotOpen();
        players.push(payable(msg.sender));

        emit LotteryEnter(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = s_lotteryState == State.OPEN;
        bool intervalPassed = (block.timestamp - s_lastBlockTimestamp) >
            i_interval;
        bool hasPlayers = players.length > 0;
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded = isOpen && intervalPassed && hasPlayers && hasBalance;
        return (upkeepNeeded, "");
    }

    function performUpkeep(
        bytes memory /* performData */
    ) external override {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded)
            revert Lottery__UpkeepNotNeeded(
                address(this).balance,
                players.length,
                uint256(s_lotteryState)
            );

        s_lotteryState = State.CALCULATING;
        uint256 requestId = i_coordinator.requestRandomWords(
            i_gasLane, //gasLane _ max gas price you are willing to pay for a reques
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedLotteryWinner(requestId);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        uint256 lotteryWinnerIndex = randomWords[0] % players.length;
        address payable recentWinner = players[lotteryWinnerIndex];
        s_recentWinner = recentWinner;
        players = new address payable[](0);
        s_lastBlockTimestamp = block.timestamp;
        s_lotteryState = State.OPEN;

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransactionFailed();
        }

        emit WinnerPicked(recentWinner);
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }
}
