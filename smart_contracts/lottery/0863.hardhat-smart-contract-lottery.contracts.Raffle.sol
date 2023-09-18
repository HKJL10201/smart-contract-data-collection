//Raffle
// Enter the lottery (1Eth per entry)
// Pick a random s_winner
// s_winner selection to be selected per week
// use a chainlink oracle for randomness
// automated execution (chainlink keepers)

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

error enterRaffle__insufficientAmount();
error Raffle__TransferFailed();
error Raffle__NotOpened();
error Raffle__UpKeepNotNeeded(
    uint256 currentBalance,
    uint256 participants,
    uint256 raffleState
);
error Raffle_UnAuthorised();

/**
 * @title A Sample Raffle Contract
 * @author ejmorian
 * @notice This contract is for creating a untamperable decentralise smart contracts
 * @dev this implements chainlink VRFV2 and chainlink keepers
 */

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /**Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    modifier OnlyOwner() {
        if (msg.sender != s_owner) {
            revert Raffle_UnAuthorised();
        }
        _;
    }

    /* State Variables */
    address private immutable s_owner;
    address payable[] public s_participants;
    uint256 private s_previousTimestamp;
    RaffleState private s_raffleState;
    address private s_winner;

    uint32 private immutable i_callBackGaslimit;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subId;
    uint256 private immutable i_entranceFee;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint256 private immutable i_interval;

    uint16 private constant c_requestConfirmation = 3;
    uint32 private constant c_numWords = 1;

    /* Events */
    event RaffleEnter(address indexed participant);
    event requestedRaffles_winner(uint256 indexed requestId);
    event s_winnerPicked(address indexed recents_winner);

    /**Functions */
    constructor(
        address vrfCoordinatorV2, // 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        bytes32 keyHash, // 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c
        uint256 entranceFee,
        uint64 subId,
        uint32 callBackGaslimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_keyHash = keyHash;
        i_subId = subId;
        i_callBackGaslimit = callBackGaslimit;
        i_interval = interval;
        s_raffleState = RaffleState.OPEN;
        s_previousTimestamp = block.timestamp;
        s_owner = msg.sender;
    }

    function enterRaffle() external payable {
        // require(msg.value > i_entranceFee)
        if (msg.value < i_entranceFee) {
            revert enterRaffle__insufficientAmount();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpened();
        }

        s_participants.push(payable(msg.sender));

        emit RaffleEnter(msg.sender);
    }

    function pickRandomWinner() internal {
        s_raffleState = RaffleState.CALCULATING;
        //request the random number
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subId,
            c_requestConfirmation,
            i_callBackGaslimit,
            c_numWords
        );
        //once we get it, do something with it
        // 2 transaction process

        emit requestedRaffles_winner(requestId);
    }

    function payWinner(address payable winner) internal {
        (bool success, ) = payable(winner).call{value: address(this).balance}(
            ""
        );

        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 s_winnerIndex = randomWords[0] % s_participants.length;
        s_winner = s_participants[s_winnerIndex];

        payWinner(payable(s_winner));

        s_participants = new address payable[](0);
        s_previousTimestamp = block.timestamp;
        if (s_raffleState != RaffleState.OPEN) {
            s_raffleState = RaffleState.OPEN;
        }

        emit s_winnerPicked(s_winner);
    }

    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /*performData*/)
    {
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool intervalPassed = (block.timestamp - s_previousTimestamp) >
            i_interval;
        bool hasPlayers = s_participants.length > 0;
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded = isOpen && intervalPassed && hasPlayers && hasBalance;
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        (bool upKeepNeeded, ) = checkUpkeep("");

        if (!upKeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_participants.length,
                uint256(s_raffleState)
            );
        }

        s_previousTimestamp = block.timestamp;

        pickRandomWinner();
    }

    function setRaffleState(RaffleState _state) public OnlyOwner {
        s_raffleState = _state;
    }

    /** pure/view */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getParticipant(uint256 index) public view returns (address) {
        return s_participants[index];
    }

    function getParticipantNumbers() public view returns (uint256) {
        return s_participants.length;
    }

    function getWinner() public view returns (address) {
        return s_winner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getPreviousTimestamp() public view returns (uint256) {
        return s_previousTimestamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getKeyHash() public view returns (bytes32) {
        return i_keyHash;
    }

    function getVrfCoordinator()
        public
        view
        returns (VRFCoordinatorV2Interface)
    {
        return i_vrfCoordinator;
    }

    function getSubId() public view returns (uint64) {
        return i_subId;
    }

    function getCallBackGasLimit() public view returns (uint32) {
        return i_callBackGaslimit;
    }

    // function pickRandomWinner() external {}
}
