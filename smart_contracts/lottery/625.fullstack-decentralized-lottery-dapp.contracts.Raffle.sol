// Raffle
// Enter the Lottery (Pay in some amount)
// Pick a Random winner
// Winner to be selected every x time -> Completely automated
// Chainlink Oracle => Randomness, Automated Execution(Chainlink Keepers)

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

// Error code for insufficient entrance fee
error Raffle__NotEnoughEthEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpKeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
);

/**@title A sample Raffle Contract
 * @author Clinton Felix
 * @notice This contract is for creating an untamperable decentralized Smartcontract Lottery
 * @dev This implements ChainLink VRF-v2 and ChainLink Keepers
 */

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /** State Variables **/
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; // private immutable because we are setting once in constructor
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // caps writing for constant variables
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    uint256 private immutable i_entranceFee; // entrance fee will not change, hence private immutability.
    address payable[] private s_players; //keep track of all list of players that enter the lottery
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval; // will not change after deployment

    /** Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /** Functions **/
    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane, // keyhash
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    // Function allows anyone to join the raffle by making payment; hence payable
    function enterRaffle() public payable {
        // require that the message value is greater than entrance fee
        // using the if error code method is more gas efficient than require
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthEntered();
        }

        // require people to enter if the Lottery is open
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }

        // add the player address to the list of players array (note payability)
        s_players.push(payable(msg.sender));

        // emit an event when we update a dynamic array or mapping
        // naming convention for event is by reversing the function name
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * They look for the upKeepNeeded to return True
     * The following should be true in order to return True:
     * 1. Our time interval should have passed
     * 2. Lottery should have at least 1 player and funded with ETH
     * 3. Our subscription should be funded with LINK
     * 4. Lotter Should be in an "open" state
     **/

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upKeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = RaffleState.OPEN == s_raffleState; //ensures raffle is open
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval); // require (block.timestamp - lasttimestamp) > interval
        bool hasPlayers = (s_players.length > 0); // ensures we have players logged
        bool hasBalance = (address(this).balance > 0);
        upKeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    // pick the Random winner with the help of chainlink VRF and Keepers
    function performUpkeep(
        bytes calldata /*performData*/
    ) external override {
        (bool upKeepNeeded, ) = checkUpkeep("");

        if (!upKeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        // Request a verifiable random Number
        // Once we get it, do something with it
        // It is a 2 transaction process
        s_raffleState = RaffleState.CALCULATING; // closes the raffle so no one can enter when we are calculating random no.
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gas lane, which tells chainlink the mx gas you are willing to pay in wei
            i_subscriptionId, // subscription needed for funding the random number transaction(s)
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length; // modulus operation for randomness
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN; // opens up the raffle again when we have picked our winner
        s_players = new address payable[](0); // Reset the address array after picking the winner
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner); // actually
    }

    /** View / Pure Functions **/
    // function for users to get the entrance fee of the lottery
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    // function to get the list of players by index that have joined the lottery
    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    // function to get the address of the recent winner
    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatesttimestamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}
