// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Constructor
// Functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title Raffle smart contract built with Foundry.
 * @author Nishant Vemulakonda
 * @notice This project creates a sample Raffle smart contract with Oracle based true randomness
 * @dev Implements Chainlink VRFv2
 */

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
    error Raffle__NotSentEnoughETH();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();

    enum RaffleSTATE {
        OPEN,
        CALCULATING
    }

    /* STATE VARIABLES */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_raffleEntryFee;
    /**
     * @dev Duration of the raffle in seconds
     */
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_COORDINATOR;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    address private s_recentWinner;
    uint256 private s_lastTimeStamp;
    RaffleSTATE private s_raffleState;

    /**
     * Events
     */

    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestRaffleWinner(uint256 indexed winner);

    /**
     * Modifiers
     */
    modifier checkMinimumETHSent() {
        if (msg.value < i_raffleEntryFee) {
            revert Raffle__NotSentEnoughETH();
        }
        _;
    }

    /**
     * HARDCODED FOR SEPOLIA
     * (VRF) COORDINATOR: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
     */

    constructor(
        uint256 raffleEntryFee,
        uint256 interval,
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_raffleEntryFee = raffleEntryFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleSTATE.OPEN;
    }

    function enterRaffle() external payable checkMinimumETHSent {
        if (s_raffleState != RaffleSTATE.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = s_raffleState == RaffleSTATE.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        // check if enough time has passed
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }

        s_raffleState = RaffleSTATE.CALCULATING;

        uint256 requestId = i_COORDINATOR.requestRandomWords(
            i_gasLane, // keyHash
            i_subscriptionId,
            REQUEST_CONFIRMATIONS, // default: 3
            i_callbackGasLimit,
            NUM_WORDS // default: 2 random numbers
        );

        emit RequestRaffleWinner(requestId);
    }
    // CEI: Checks, Effects, Interactions

    function fulfillRandomWords(uint256, /* requestId */ uint256[] memory randomWords) internal override {
        // Effects
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable Winner = s_players[indexOfWinner];
        s_recentWinner = Winner;
        s_raffleState = RaffleSTATE.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        // Interactions (Effects on other contracts)
        (bool success,) = Winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }

        emit PickedWinner(Winner);
    }

    /**
     * GETTERS
     */

    function getRaffleEntryFee() external view returns (uint256) {
        return i_raffleEntryFee;
    }

    function getRaffleState() external view returns (RaffleSTATE) {
        return s_raffleState;
    }

    function getRafflePlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getNumberOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}
