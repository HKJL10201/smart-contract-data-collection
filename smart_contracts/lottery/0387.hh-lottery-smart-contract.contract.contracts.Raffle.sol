// SPDX-License-Identifier: MIT
/**
 * tasks
 * - Enter in lottery ( make some payment )
 * - pick random winner ( verifiable random )
 * - Winner to be selected every x mins
 */
/*
    Chainlink oracle
    1. For Randomness
    2. For Automated execution
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "hardhat/console.sol";

error Raffle__NotEnoughEthEntered();
error Raffle__WithdrawalFail();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numberOfPlayers,
    uint256 raffleState
);

/**
 * @title Contract for Raffle
 * @author rajanlagah
 * @notice decentralized Contract to host lottery one after another
 * @dev This impelements chainlink vrf2 and chain link keepers
 */

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    uint256 private immutable i_entryFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCordinator;

    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane; // each gasLane have max gas limit to protect us paying tons of money
    address private immutable i_subscrvrfCordinatorV2_add;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant RANDOM_REQUEST_NUMBER_CONFIRMATION = 3;
    uint32 private constant RANDOM_NUMBER = 1;

    address private s_winner;
    RaffleState private s_raffleState;
    uint256 public immutable i_interval;
    uint256 public s_timeOfLastReset;

    event Log(string message);
    event LogBytes(string data);

    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnersPicked(address indexed winnerAddress);

    constructor(
        address vrfCordinatorV2,
        uint256 entryFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCordinatorV2) {
        i_vrfCordinator = VRFCoordinatorV2Interface(vrfCordinatorV2);
        i_subscrvrfCordinatorV2_add = vrfCordinatorV2;
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_entryFee = entryFee;
        s_raffleState = RaffleState.OPEN;
        s_timeOfLastReset = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
    }


    function enterRaffle() public payable {
        if (msg.value < i_entryFee) {
            revert Raffle__NotEnoughEthEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    function fulfillRandomWords(
        uint256, // _requestId,
        uint256[] memory _randomWords
    ) internal override {
        s_raffleState = RaffleState.OPEN;
        uint256 winnerIndex = _randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_players = new address payable[](0);
        s_timeOfLastReset = block.timestamp;
        s_winner = winner;
        (bool success, ) = winner.call{value: address(this).balance}("");

        if (!success) {
            revert Raffle__WithdrawalFail();
        }
        emit WinnersPicked(winner);
    }

    /**
     * @dev this is the function that chainlink keeper node call
     * they look `upkeepNeeded` to return true
     * The following needs to be true for it to return true
     * 1. Time interval should have past
     * 2. atleast 1 player in game
     * 3. contract must have some eth
     * 4. We have some link for transaction in contract
     * 5. Lottery to b in openstate
     */

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        console.log("check up keep called");
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool isIntervalOver = ((block.timestamp - s_timeOfLastReset) >
            i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && isIntervalOver && hasPlayers && hasBalance);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;
        uint256 _requestId = i_vrfCordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            RANDOM_REQUEST_NUMBER_CONFIRMATION,
            i_callbackGasLimit,
            RANDOM_NUMBER
        );
        emit RequestedRaffleWinner(_requestId);
    }

    /* View / Pure functions */
    function getConfig()
        public
        view
        returns (
            address vrfCordinatorV2,
            uint256 entryFee,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            uint256 interval,
            VRFCoordinatorV2Interface vf
        )
    {
        return (
            i_subscrvrfCordinatorV2_add,
            i_entryFee,
            i_gasLane,
            i_subscriptionId,
            i_callbackGasLimit,
            i_interval,
            i_vrfCordinator
        );
    }

    function getEntryFee() public view returns (uint256) {
        return i_entryFee;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getPlayer(uint256 _index) public view returns (address) {
        return s_players[_index];
    }

    function getWinner() public view returns (address) {
        return s_winner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_timeOfLastReset;
    }
}
