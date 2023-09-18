// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
/*
 * @title Sample Raffle Contract
 * @author Shivendra Singh
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 */

error Raffle__NotEnoughETHSent();
error Raffle__TransferFailed();
error Raffle__RaffleNotOpen();
error Raffle__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
);

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    // ENUM
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    // STATE variables
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    // ChainLink VRFv2 variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private s_lastTimeStamp;
    address payable[] s_players;
    address public s_recentWinner;
    RaffleState private s_raffleState;

    // EVENTS
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRandomWords(uint256 indexed vrfRequestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfcoordinator,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfcoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfcoordinator);
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSent();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
    @dev Check Upkeep should fulfill the following conditions:
    1. Enough time should have passed between last lottery and present
    2. There should be players 
    3. The lottery should be OPEN
    4. and ETH in the contract
  */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool enoughTimeHasPassed = (block.timestamp - s_lastTimeStamp) >=
            i_interval;
        bool hasPlayers = s_players.length > 0;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasETH = address(this).balance > 0;

        upkeepNeeded = (enoughTimeHasPassed && hasPlayers && isOpen && hasETH);
        return (upkeepNeeded, "0x0");
    }

    /*  
        @dev: performUpKeep() will find the lottery winner
        1. Get a random no.
        2. Use the random no. to pick a winner
        3. Be automatically triggered
    */
    function performUpkeep(bytes calldata /* performData */) external {
        // checking if sufficient interval has been given for the lottery to work
        (bool upKeepNeeded, ) = checkUpkeep("");

        if (!upKeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;

        // Will revert if subscription is not set and funded.
        uint256 vrfRequestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRandomWords(vrfRequestId);
    }

    /*
    CEI design pattern: Checks, Effects, Interactions
    @dev: fulfillRandomWords function is auto called once requestRandomWords gets the random words from the oracles
     */

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;

        // resetting Raffle states
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);
        /*  Emit should be ideally done after the award has been successfully creditted to the winner, 
            but following the CEI design pattern, since emitting is an 'Effect', 
            it should be placed above the Interaction */

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) revert Raffle__TransferFailed();
    }

    // GETTER FUNCTIONS
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getRafflePlayer(
        uint256 indexOfPlayer
    ) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
