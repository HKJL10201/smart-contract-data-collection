// Raffle
// This contract represents a simple raffle where participants can enter by paying an entrance fee.
// A random winner will be selected every X minutes, with the randomness obtained from a Chainlink Oracle.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//in order to make our raffle contract VRF'able we have to import the chainlink code
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
// Error to be thrown when a participant hasn't paid enough ETH as entrance fee.
error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

/**@title A sample Raffle Contract
 * @author Patrick Collins
 * @notice This contrcat os for creating an untamperable decentralized smart contract
 * @dev This implements Chianlink VRF v2 and Chainlink Keepers
 */

//in order to make our raffle contract VRF'able we have to import the chainlink code
contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /** Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Variable */
    uint256 private immutable i_entranceFee; // The entrance fee required to enter the raffle. Immutable to save gas costs.

    address payable[] private s_players; // An array to keep track of all the players who have entered the raffle.

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;

    /** lottery variables */
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /*Event*/
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestedId);
    event WinnerPicked(address indexed winner);

    /*Functions*/
    // Constructor to set the entrance fee when deploying the contract.
    constructor(
        address vrfCoordinatorV2, //contract
        uint256 entranceFee,
        bytes32 gasLane,
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

    // Function to allow participants to enter the raffle by paying the entrance fee.
    function enterRaffle() public payable {
        // Check if the sent value is sufficient to cover the entrance fee.
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered(); // Throw an error if the entrance fee requirement is not met.
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }

        // Add the participant to the list of players who have entered the raffle.
        s_players.push(payable(msg.sender));
        //Emit an event when we update a dynamic array or mapping
        //syntax for Named events with the function name reversed
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * They look for the `upkeepNeeded` to return true
     * in od=rder for it to be time to request a random winner:
     * 1. Our time inteval should have passed
     * 2. The lottery should have at least 1 player, and hahve some ETH
     * 3. Our subscription is funded with LINK
     * (checkUpKeep and Keepers have to be funded with LINK too)
     * 4. Lottery should be in a open state
     */

    function checkUpkeep(
        bytes memory /*checkData */
    ) public override returns (bool upkeepNeeded, bytes memory /**performData */) {
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        //block.timestamp returns the current time stamp of the blockchain
        // to check if the time interval has passed: (block.timestamp - last block.timestamp) > interval
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(bytes calldata /* performData*/) external override {
        // we use external instead of public because its cheaper
        //it is 2 transaction process: Request the random number and; Do something with it
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //gasLane
            i_subscriptionId, // has to be funded with LINK
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /* requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length; //this means when the randomnumber generated is divided by the number of players, the remainder is assigned to the indexOfWinner
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_players = new address payable[](0); // to reset the plalyers after a winner is picked

        (bool success, ) = recentWinner.call{value: address(this).balance}(""); // To transfer the funds to the winner

        //require(success)
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* View /Pure functions */

    // Function to get the configured entrance fee.
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    // Function to get a player's address by providing their index in the players' array.
    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATION;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}
