// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// errors
error Lottery__NotEnoughETH();
error Lottery__TransferFailed();
error Lottery__NotOpen();
error Lottery_UpKeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 lotteryState);

contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* enums */
    enum LotteryState {
        Open,
        Calculating
    }

    /* state variables */
    uint256 private immutable entranceFee;
    VRFCoordinatorV2Interface private vrfCoordinator;
    bytes32 private immutable gasLane;
    uint64 subscriptionId;
    uint32 private immutable callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    address payable[] private players;
    uint256 private lastTimeStamp;
    uint256 private immutable interval;

    address recentWinner;
    LotteryState private lotteryState;

    /* events */
    event RaffleEntered(address indexed player);
    event RequestedLotteryWinner(uint256 requestId);
    event WinnerPicked(address recentWinner);

    constructor(
        address _vrfCoordinator,
        uint256 _entranceFee,
        uint256 _interval,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        entranceFee = _entranceFee;
        interval = _interval;
        gasLane = _gasLane;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        lastTimeStamp = block.timestamp;
    }

    function enterLottery() public payable {
        if (msg.value < entranceFee) {
            revert Lottery__NotEnoughETH();
        }
        if (lotteryState != LotteryState.Open) {
            revert Lottery__NotOpen();
        }
        players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    // called by chainlink keeper nodes (offchain) to determine if upkeep is needed
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = lotteryState == LotteryState.Open;
        bool timePassed = (block.timestamp - lastTimeStamp) > interval;
        bool hasPlayers = players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(
        bytes calldata /*performData*/
    ) external override {
        // (bool upkeepNeeded, ) = checkUpkeep("");
        // revalidate upkeep logic, best practice
        bool upkeepNeeded = _upkeepNeeded();
        if (!upkeepNeeded) {
            revert Lottery_UpKeepNotNeeded(
                address(this).balance,
                players.length,
                uint256(lotteryState)
            );
        }
        // Will revert if subscription is not set and funded.
        uint256 requestId = vrfCoordinator.requestRandomWords(
            gasLane,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS
        );
        lotteryState = LotteryState.Calculating;
        emit RequestedLotteryWinner(requestId);
    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % players.length;
        address payable winner = players[indexOfWinner];
        recentWinner = winner;
        players = new address payable[](0);
        lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
        lotteryState = LotteryState.Open;
        emit WinnerPicked(recentWinner);
    }

    // revalidate upkeep logic, best practice
    function _upkeepNeeded() internal view returns (bool) {
        bool isOpen = lotteryState == LotteryState.Open;
        bool timePassed = (block.timestamp - lastTimeStamp) > interval;
        bool hasPlayers = players.length > 0;
        bool hasBalance = address(this).balance > 0;
        return (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function getEntranceFee() public view returns (uint256) {
        return entranceFee;
    }

    function getPlayer(uint256 _index) public view returns (address) {
        return players[_index];
    }

    function getRecentWinner() public view returns (address) {
        return recentWinner;
    }

    function getLotteryState() public view returns (LotteryState) {
        return lotteryState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return players.length;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return lastTimeStamp;
    }

    function getRequestConfirmatons() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return interval;
    }
}
