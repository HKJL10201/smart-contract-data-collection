// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Bingo__NotEnoughtETH();
error Bingo__WinnerTransactionFailed();
error Bingo__BingoStateIsNotOpen();
error Bingo__UpKeepNotNeeded(
    uint accountBalance,
    uint noOfPlayers,
    uint bingoState
);

/**@title A sample Bingo (Lottery) Contract
 * @author ABDul Rehman aka AB Dee aka Dev AB Dee :)
 * @dev This implements the Chainlink VRF Version 2 & Chainlink keepers
 */

contract Bingo is VRFConsumerBaseV2, KeeperCompatibleInterface {
    enum BingoState {
        OPEN,
        CALCULATING
    }

    uint private immutable i_entranceFee;
    address payable[] private players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 2;

    address private bingoWinner;
    BingoState private bingoState;
    uint256 private lastBlockTimeStamp;
    uint256 private immutable i_interval;

    event BingoEnter(address indexed player);
    event RequestBingoWinner(uint indexed requestId);
    event WinnerBingo(address indexed winner);

    constructor(
        bytes32 gasLane,
        address vrfCoordinatorV2,
        uint entranceFee,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_entranceFee = entranceFee;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        bingoState = BingoState.OPEN;
        lastBlockTimeStamp = block.timestamp;
        i_interval = interval;
    }

    function enterBingo() public payable {
        if (msg.value <= i_entranceFee) {
            revert Bingo__NotEnoughtETH();
        }
        if (bingoState != BingoState.OPEN) {
            revert Bingo__BingoStateIsNotOpen();
        }
        players.push(payable(msg.sender));
        emit BingoEnter(msg.sender);
    }

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
        bool isOpen = (BingoState.OPEN == bingoState);
        bool timePassed = ((block.timestamp - lastBlockTimeStamp) > i_interval);
        bool noOfPlayers = players.length > 0;
        bool bingoBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && noOfPlayers && bingoBalance);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Bingo__UpKeepNotNeeded(
                address(this).balance,
                players.length,
                uint(bingoState)
            );
        }

        bingoState = BingoState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestBingoWinner(requestId);
    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        uint index = randomWords[0] % players.length;
        address payable winner = players[index];
        players = new address payable[](0);
        lastBlockTimeStamp = block.timestamp;
        bingoWinner = winner;
        bingoState = BingoState.OPEN;
        (bool success, ) = winner.call{value: address(this).balance}("");
        // require(success, "bingoWinner Failed");
        if (!success) {
            revert Bingo__WinnerTransactionFailed();
        }
        emit WinnerBingo(winner);
    }

    function getEntranceFee() public view returns (uint) {
        return i_entranceFee;
    }

    function getPlayers(uint index) public view returns (address) {
        return players[index];
    }

    function getBingoWinner() public view returns (address) {
        return bingoWinner;
    }

    function getBingoState() public view returns (BingoState) {
        return bingoState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return lastBlockTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return players.length;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }
}
