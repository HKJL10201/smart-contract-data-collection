// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {VRFCoordinatorV2Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "chainlink-brownie-contracts/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title
 * @author
 * @notice
 */

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughEthsent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint currentBalance,
        uint numPlayers,
        uint raffleState
    );

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint private immutable i_entrancefee;
    uint private immutable i_interval;
    address private immutable i_vrfcoordinator;
    bytes32 private immutable i_gaslane;
    uint32 private immutable i_callbackGasLimit;
    uint64 private immutable i_subscriptionid;
    uint private s_lastTimeStamp;
    address payable[] private s_players;
    address payable s_recentWinner;
    RaffleState private s_raffleState;

    /** Events */
    event enterdRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        uint entranceFee,
        uint256 interval,
        address vrf_coordinator,
        bytes32 gaslane,
        uint64 subscriptionid,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrf_coordinator) {
        i_entrancefee = entranceFee;
        i_interval = interval;
        i_vrfcoordinator = vrf_coordinator;
        s_lastTimeStamp = block.timestamp;
        i_gaslane = gaslane;
        i_callbackGasLimit = callbackGasLimit;
        i_subscriptionid = subscriptionid;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entrancefee) {
            revert Raffle__NotEnoughEthsent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit enterdRaffle(msg.sender);
    }

    /**
     * @dev THis is the function that  the Chain link Sutomation nodes call
     * to see if its  time to perform an upkeep.
     * The following shoud be true for theis to return true:
     * 1.The time interval has passed between raffle runs
     * 2.The raffle is in the OPEN state
     * 3.The contract has ETH{aka,players}
     * 4.{Implicit}The function is funded with Link
     */

    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory /* performData*/) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers); //upkeepNeeded here checks if all conditions are satisfied and returns a bool
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /*performData*/) external {
        (bool upkeedNeeded, ) = checkUpkeep("");
        if (!upkeedNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        i_vrfcoordinator.requestRandomWords(
            i_gaslane, //gas lane
            i_subscriptionid,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fullfillRandomWords(
        uint requestId,
        uint[] memory randomWords
    ) internal override {
        uint indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = winner.call{value: address(this).balance("")};
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit PickedWinner(winner);
    }
}
