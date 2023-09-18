// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title Lottery smart contract
 * @author Manish Thulung
 * @notice this is a sample smart contract fot lottery
 */
contract Raffle is VRFConsumerBaseV2 {
    /** Error */
    error Raffle__LowEntraceFee();
    error Raffle__TransferFailed();
    error Raffle__RaffleStateNotOpen();
    error Raffle_UpKeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    /** Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /** State variables */
    uint16 private constant BLOCK_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;

    RaffleState private s_raffleState;

    /** Events */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() public payable {
        if (i_entranceFee > msg.value) {
            revert Raffle__LowEntraceFee();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleStateNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev this is the function that chainlink automation nodes call to if its time to perform upkeep
     * it needs following conditions fulfilled to return true
     * 1. the time interval has passed
     * 2. the raffle is in OPEN state
     * 3. the raffle must have some players (ETH)
     * 4. the subscription is funded with link
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /*performData*/) {
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasSomePlayer = s_players.length >= 1;
        bool hasSomeEth = address(this).balance > 0;
        /**
         * if 1000-500 = 500 > 600 -> not enough time has passed
         * if 1200-500 = 700 > 600 -> enough time has passed DONE
         */
        bool hasTimePassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        upkeepNeeded = (isOpen && hasSomePlayer && hasTimePassed && hasSomeEth);
        return (upkeepNeeded, "");
    }

    // function pickWinner() external {
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle_UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            BLOCK_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        // this is redundant
        emit RequestedRaffleWinner(requestId);
    }

    /** Check, Effect, Interactions */
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords // the actual random number
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0); // resetin an array to 0
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /** Getter functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getAllPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}
