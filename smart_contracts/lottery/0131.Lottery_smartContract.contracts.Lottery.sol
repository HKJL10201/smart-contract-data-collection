/*  1. Enter lottery by paying some amount
2. Pick a random winner (varifiably random through Chainlink Randoness)
3. Winner automatically selected at specific time interval through Chainlink Keepers*/

// Improvements.
//1. use USD instead of eth. Coinmarket api. uint256 private constant minimumUSD = 50 * 10 ** 18;
//2. Collect fees for operating and function for withdrawal by owner
//3. Use bytes calldata and checkdata for abi.encode.
//4. How will I be able to update this contract. 

// Questions
// 1. Are interface functions ment to be override and doesn't need a vitual keywood on function
// 2. How can use performData. Have checkupkeep do other stuff
// 3. What does byte do.
// 4. you don't need 'virtual' keywood in inference to 'override' (performData)

//Notes. deploy starts at 14:57

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/* Errors */
error Lottery__NotEnoughFeeEntered(uint256 i_entranceFee);
error Lottery__TransferFailed();
error Lottery__NotOpen();
error Lottery__UpKeepNoteNeeded(uint currentBalance, uint numPlayers, uint256 LotteryState);

/** @title Lottery Contract
 * @author Dan She
 * @notice
 * @dev implements the Chainlink VRF Version 2 and Chinlink Keepers
 */

contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /*Types declarations*/

    enum LotteryState {
        OPEN,
        CALCULATING
    }
    /*   State variables
    Chainlink VRF Variables */

    uint256 private immutable i_entranceFee;
    address[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    /* Lottery Variables */

    address private s_recentWinners;
    LotteryState private s_lotteryState;
    uint256 private s_lastTimeStamp;
    uint private immutable i_interval;

    /* Events */

    event LotteryEntered(address indexed player);
    event RequstedLotteryWinner(uint256 indexed requestId);
    event WinnersPicked(address indexed winner);

    /* Functions */
    constructor(
        address vrfCoordinatorV2, //contract address
        uint256 entranceFee,
        bytes32 gasLine,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2); //wrapping vrfCoordinatorV2 in VRFCoordinatorV2Interface allows your contract to interact with the vrfCoordinatorV2 contract using the functions defined in VRFCoordinatorV2Interface.
        i_gasLane = gasLine;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    function enterLottery() public payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughFeeEntered(uint256(i_entranceFee));
        }
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__NotOpen();
        }
        s_players.push(payable(msg.sender)); //msg.sender isn't payable, need to wrap by typecast payble
        // Emit an event when we update a dynamic array or mapping
        emit LotteryEntered(msg.sender);
    }

    /*This is the function that Chainlink Keepers node call, they look for return 'true'*/
    function checkUpkeep(
        bytes memory /*checkData*/   
    ) public override returns (bool upKeepNeeded, bytes memory /*performData*/) {
        bool isOpen = (LotteryState.OPEN == s_lotteryState);
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upKeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Lottery__UpKeepNoteNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }
    }

    function requestRandomWords() external {
        s_lotteryState = LotteryState.CALCULATING;
        uint requestId = i_vrfCoordinator.requestRandomWords(
            //1. request random number 2. Derive winner from random number. 2 step transaction to avoid brute force attack
            i_gasLane, //gasLine
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequstedLotteryWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestID*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address recentWinner = payable(s_players[indexOfWinner]);
        s_recentWinners = recentWinner;
        s_lotteryState = LotteryState.OPEN;
        s_players = new address payable[](0); //reset s_players array
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
        emit WinnersPicked(recentWinner);
    }

    /* Getter Functions*/

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinners;
    }

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLastestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }
}
