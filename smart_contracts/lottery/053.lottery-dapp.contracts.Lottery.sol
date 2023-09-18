// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';

error NotEnoughEntranceFee();
error LotteryNotOpen();
error UpkeepNotNeeded();
error TransferFailed();

contract Lottery is VRFConsumerBaseV2 {
    enum LotteryState {
        Open,
        Calculating
    }

    LotteryState public lotteryState;
    VRFCoordinatorV2Interface public vrfCoordinatorV2;

    uint256 public immutable entranceFee;
    uint256 public immutable interval;

    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;

    uint256 public lastTimestamp;
    uint64 public subscriptionId;
    uint32 public callbackGasLimit;

    bytes32 gasLane;

    address payable[] public players;
    address public recentWinner;

    event LotteryEntered(address indexed player);
    event RequestLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinatorV2,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        entranceFee = _entranceFee;
        interval = _interval;
        lastTimestamp = block.timestamp;
        vrfCoordinatorV2 = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        gasLane = _gasLane;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
    }

    function enterLottery() external payable {
        if (msg.value < entranceFee) {
            revert NotEnoughEntranceFee();
        }

        if (lotteryState != LotteryState.Open) {
            revert LotteryNotOpen();
        }

        players.push(payable(msg.sender));
        emit LotteryEntered(msg.sender);
    }

    function checkUpkeep(bytes memory) public view returns (bool upkeepNeeded, bytes memory) {
        bool isOpen = LotteryState.Open == lotteryState;
        bool timePassed = (block.timestamp - lastTimestamp) > interval;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = players.length > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, '0x0');
    }

    function performUpkeep(bytes calldata) external {
        (bool upkeepNeeded, ) = checkUpkeep('');
        if (!upkeepNeeded) {
            revert UpkeepNotNeeded();
        }
        lotteryState = LotteryState.Calculating;
        uint256 requestId = vrfCoordinatorV2.requestRandomWords(
            gasLane,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS
        );

        emit RequestLotteryWinner(requestId);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % players.length;
        address payable _recentWinner = players[indexOfWinner];
        recentWinner = _recentWinner;
        players = new address payable[](0);
        lotteryState = LotteryState.Open;
        lastTimestamp = block.timestamp;
        (bool success, ) = _recentWinner.call{value: address(this).balance}("");
        
        if (!success) {
            revert TransferFailed();
        }

        emit WinnerPicked(_recentWinner);
    }
}
