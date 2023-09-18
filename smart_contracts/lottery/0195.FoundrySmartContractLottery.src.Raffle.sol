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

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/*
 * @title A sample Raffle contract
 * @author Favour Afenikhena
 * @notice This contract is a sample raffle contract
 * @dev Implements CHainlink VRFV2
 */

contract Raffle is VRFConsumerBaseV2 {
    /*  Errors */
    error Raffle__NotEnoughEthSent();
    error Raffle__NotEnoughTimePast();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOPen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    //  biil lotterystate = open, closed, calculating

    /*  Type Declarating  */
    enum RaffleState {
        OPEN, // 0
        CALCUALTING // 1
    }

    /*  State variables */

    // constants variables
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // immutable variables
    uint256 private immutable i_entranceFee;
    // @dev duration of the lettery in seconds
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    //  sotrage variables
    address payable[] private s_players;
    address private s_recentWinner;
    uint256 private s_lastTimestamp;
    RaffleState private s_raffleState;

    /*  Events  */
    event EnterRaffle(address indexed player);
    event PickedWinner(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimestamp = block.timestamp;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        // open the raffle state
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOPen();
        }
        //  add the user to the list of people to be paid
        s_players.push(payable(msg.sender));
        // 1. Makes Migrarion easier
        // 2. Makes front end index easier
        emit EnterRaffle(msg.sender);
    }

    /*
     * @dev This is the function that the chaninlink automation nodes call
     * to see if tis time to perform an upkeep
     * The folllowing should be true for this to return true ;
     * 1. The time intervl has passed between raffle runs
     * 2. The raff is in the open state
     * 3. The contact has eth ( aka, players )
     * 4. ( implicit ) The subscription is funded with link
     */
    function checkUpKeep(bytes memory /* checkdata */ )
        public
        view
        returns (bool upKeepNeeded, bytes memory /*  performData */ )
    {
        bool timeHasPassed = block.timestamp - s_lastTimestamp >= i_interval;
        bool isOPen = RaffleState.OPEN == s_raffleState;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        // this to check if all true
        upKeepNeeded = (timeHasPassed && isOPen && hasPlayers && hasBalance);
        return (upKeepNeeded, "0x0");
    }

    function performUpKeep(bytes calldata /* performData */ ) external {
        /* Pick WInnner */
        // Get a random number
        // Use the random numnber to pick a player

        // 1000 - 500 = 500  . 600 seconds
        // 1200 - 500 = 700  . 600 seconds
        (bool upKeepNeeded,) = checkUpKeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        // 1. Request the RNG <-
        // 2. Get the Random Number
        // Will revert if subscription is not set and funded.
        // set raffle to calcualting
        s_raffleState = RaffleState.CALCUALTING;
        //  now no one canter enter till done
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gas lane
            i_subscriptionId, // id funded with link
            REQUEST_CONFIRMATIONS, // number of block confimations
            i_callbackGasLimit, // gas limit
            NUM_WORDS // number of random number
        );

        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256, /* requestId */ uint256[] memory randomWords) internal override {
        // s_palyers = 10
        // rng = 12
        // 12 % 10 = 2 <-
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        // reset the values
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        // send the winner the money
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        // set the state to open
        s_raffleState = RaffleState.OPEN;
        // emit the log
        emit PickedWinner(winner);
    }

    /* Getter Function  */

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) public view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLengthOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimestamp;
    }
}
