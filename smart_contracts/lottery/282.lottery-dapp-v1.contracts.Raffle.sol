// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

error Raffle__SendMoreToEnterRaffle();
error Raffle__NotSended();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
error Raffle__NotOpen();

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    enum State {
        OPEN,
        PENDING
    }

    /* VRF Variables*/

    VRFCoordinatorV2Interface s_COORDINATOR;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 constant callbackGasLimit = 100000;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant NUMWORDS = 1;
    uint256 public s_randomWords;

    /* State Variables*/

    uint256 private immutable i_entranceFee; // Threshold for entering the lottery, we will compare with msg.value so it should be in wei
    address payable[] private s_players;
    address private s_lastWinner;
    State public status = State.OPEN;
    uint256 private lastTimeStamp;
    uint256 private immutable i_interval;
    uint256 private s_raffleIndex;

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);

    /*Constructor*/
    constructor(
        uint256 entranceFee,
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinator) {
        s_COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        i_entranceFee = entranceFee;
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        lastTimeStamp = block.timestamp;
        i_interval = interval;
        s_raffleIndex = 0;
    }

    //external

    function enterRaffle() external payable {
        if (status != State.OPEN) {
            revert Raffle__NotOpen();
        }
        if (msg.value < i_entranceFee) {
            // msg.value is in the wei format
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords[0];
        address payable winner = s_players[s_randomWords % s_players.length];
        s_lastWinner = winner;
        s_players = new address payable[](0); // Reset the players
        (bool sent, ) = winner.call{value: address(this).balance}("");
        if (!sent) {
            revert Raffle__NotSended();
        }
        emit WinnerPicked(s_lastWinner);
        s_raffleIndex++;
        status = State.OPEN;
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
        bool intervalState = ((block.timestamp - lastTimeStamp) > i_interval);
        bool okState = (status == State.OPEN);
        bool hasPlayers = (s_players.length > 1);
        bool hasBalance = (address(this).balance > 0);

        upkeepNeeded = (intervalState && okState && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");

        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(status)
            );
        }
        status = State.PENDING;

        uint256 requestId = s_COORDINATOR.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUMWORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function getLastWinner() public view returns (address) {
        return s_lastWinner;
    }

    function getRaffleState() public view returns (State) {
        return status;
    }

    function getNumWords() public pure returns (uint256) {
        return NUMWORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getRaffleIndex() public view returns (uint256) {
        return s_raffleIndex;
    }
}
