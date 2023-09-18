// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

enum LotteryState {
    OPEN,
    CALCULATING
}

error Lottery__NotEnoughETH();
error Lottery__TransferFailed();
error Lottery__NotOpen();
error Lottery__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    LotteryState state
);

contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
    uint256 public immutable playFee;
    address payable[] private players;
    address payable private lastWinner;
    uint16 private immutable interval;
    LotteryState private state;

    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    bytes32 private immutable gaslane;
    uint64 private immutable subscriptionID;
    uint32 private immutable gasLimit;
    uint32 private constant words = 1;
    uint16 private constant blockConfirmation = 3;
    uint256 private previousTimestamp;

    event LotteryEnter(address indexed player);
    event RequestedWinner(uint256 indexed requestID);
    event WinnerPicked(address indexed winner);

    constructor(
        address _vrfCoordinatorV2,
        uint256 _fee,
        bytes32 _gaslane,
        uint64 _subscriptionID,
        uint32 _gasLimit,
        uint16 _interval
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        playFee = _fee;
        gaslane = _gaslane;
        subscriptionID = _subscriptionID;
        gasLimit = _gasLimit;
        state = LotteryState.OPEN;
        previousTimestamp = block.timestamp;
        interval = _interval;
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
    }

    modifier checkState() {
        if (state != LotteryState.OPEN) {
            revert Lottery__NotOpen();
        }
        _;
    }

    function getPlayFee() public view returns (uint256) {
        return playFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return players[index];
    }

    function getWinner() public view returns (address) {
        return lastWinner;
    }

    function getLatestTimestamp() public view returns (uint256) {
        return previousTimestamp;
    }

    function getLotteryState() public view returns (LotteryState) {
        return state;
    }

    function getInterval() public view returns (uint256) {
        return interval;
    }

    function play() public payable checkState {
        if (msg.value < playFee) {
            revert Lottery__NotEnoughETH();
        }

        players.push(payable(msg.sender));
        emit LotteryEnter(msg.sender);
    }

    function checkUpkeep(bytes memory)
        public
        override
        returns (bool upkeepNeeded, bytes memory)
    {
        upkeepNeeded =
            (LotteryState.OPEN == state) &&
            ((block.timestamp - previousTimestamp) > interval) &&
            (players.length > 0) &&
            (address(this).balance > 0);
    }

    function performUpkeep(bytes calldata) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded(
                address(this).balance,
                players.length,
                state
            );
        }
        winner();
    }

    function winner() internal {
        state = LotteryState.CALCULATING;
        uint256 requestID = vrfCoordinator.requestRandomWords(
            gaslane,
            subscriptionID,
            blockConfirmation,
            gasLimit,
            words
        );

        emit RequestedWinner(requestID);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        lastWinner = players[randomWords[0] % players.length];

        (bool success, ) = lastWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }

        resetPlayer();
        previousTimestamp = block.timestamp;
        state = LotteryState.OPEN;

        emit WinnerPicked(lastWinner);
    }

    function resetPlayer() internal {
        players = new address payable[](0);
    }
}
