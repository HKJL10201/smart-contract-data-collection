// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "hardhat/console.sol";

error Lottery__SendMoreETHToParticipate();
error Lottery__TransferFailed();
error Lottery__StateIsNotOpen();
error Lottery__WinnerShouldNotBePicked(
    uint256 balance,
    uint256 playersLength,
    uint256 state
);

/**
 * @title A Lottery Contract
 * @author Benas Volkovas
 * @dev Smart contract uses verified random numbers (VRF) and decentralized automation (Keepers)
 */
contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Type declarations */
    enum LotteryState {
        Open,
        Calculating
    }

    /* State variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    VRFCoordinatorV2Interface private immutable VRF_COORDINATOR;
    uint256 private immutable ENTRENCE_FEE;
    bytes32 private immutable GAS_LANE; // keyHash
    uint64 private immutable SUBSCRIPTION_ID;
    uint32 private immutable CALLBACK_GAS_LIMIT;
    uint256 private immutable INTERVAL;

    address payable[] private players;
    address private recentWinner;
    LotteryState private lotteryState;
    uint256 private lastTimestamp;

    /* Events */
    event LotteryEntered(address indexed player);
    event RequestedWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /* Functions */
    constructor(
        uint256 _entranceFee,
        address _vrfCoordinatorV2,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint256 _interval
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        ENTRENCE_FEE = _entranceFee;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        GAS_LANE = _gasLane;
        SUBSCRIPTION_ID = _subscriptionId;
        CALLBACK_GAS_LIMIT = _callbackGasLimit;
        lotteryState = LotteryState.Open;
        lastTimestamp = block.timestamp;
        INTERVAL = _interval;
    }

    function enterLottery() external payable {
        if (msg.value < ENTRENCE_FEE)
            revert Lottery__SendMoreETHToParticipate();

        if (lotteryState != LotteryState.Open) revert Lottery__StateIsNotOpen();

        players.push(payable(msg.sender));

        emit LotteryEntered(msg.sender);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        if (!_shouldPickWinner())
            revert Lottery__WinnerShouldNotBePicked(
                address(this).balance,
                players.length,
                uint256(lotteryState)
            );

        lotteryState = LotteryState.Calculating;

        uint256 requestId = VRF_COORDINATOR.requestRandomWords(
            GAS_LANE,
            SUBSCRIPTION_ID,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        emit RequestedWinner(requestId);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call.
     * They look for 'upkeepNeeded' to return true.
     * The following should be true for this to return true:
     * 1. The time interval has passed between lottery games.
     * 2. The lottery is open.
     * 3. The contract has players and ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
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
        upkeepNeeded = _shouldPickWinner();
    }

    function fulfillRandomWords(
        uint256, /* _requstId */
        uint256[] memory _randomWords
    ) internal override {
        uint256 indexOfWinner = _randomWords[0] % players.length;
        address payable winner = players[indexOfWinner];
        players = new address payable[](0);

        recentWinner = winner;
        lotteryState = LotteryState.Open;
        lastTimestamp = block.timestamp;

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) revert Lottery__TransferFailed();

        emit WinnerPicked(winner);
    }

    function _shouldPickWinner() private view returns (bool) {
        bool isOpen = (lotteryState == LotteryState.Open);
        bool timePassed = ((block.timestamp - lastTimestamp) > INTERVAL);
        bool hasPlayers = (players.length > 0);
        bool hasBalance = (address(this).balance > 0);
        return (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function getEntranceFee() public view returns (uint256) {
        return ENTRENCE_FEE;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return players[index];
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return players.length;
    }

    function getRecentWinner() public view returns (address) {
        return recentWinner;
    }

    function getLotteryState() public view returns (LotteryState) {
        return lotteryState;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return lastTimestamp;
    }

    function getInterval() public view returns (uint256) {
        return INTERVAL;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }
}
