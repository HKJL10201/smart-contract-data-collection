// Raffle
// Enter the lottery (Pay some amount)
// Pick a random winner (Verifiably random)
// Winner to be selected every X minutes -> completely automated
// Chainlink oracle (for randomness from outside the blockchain), Automated execution( using Chainlink Keepers)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughETHEntered(); // error code
error Raffle__TransferFailed(); // error code if money is not sent to winner
error Raffle__NotOpen(); // error code if raffle is not open or it is in calculating state
error Raffle__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
); // error code for upkeep not needed

/**
 * @title A sample Raffle contract
 * @author Rajdeep Ray
 * @notice This contract is for creating an untamperable decentralized smart contract
 * @dev This implements Chainlink VRF V2 and Chainlink Keepers
 */

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Type declaration*/

    // Enums restrict a variable to have one of only a few predefined values. The values in this enumerated list are called enums.
    enum RaffleState {
        OPEN,
        CALCULATING
    } // this is similar to creating a uint256 where 0 is open and 1 is calculating

    /* State Variables */
    uint256 private immutable i_entranceFee; // immutable variable saves gas
    address payable[] private s_players; // payable because if one of these player wins, we have to pay the player
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; // private and immutable because we set up our vrfCoordinator only once
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callBackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    // Lottery variables
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /* Events
    --> Events are named with function name reversed
     */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callBackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callBackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    // enterRaffle function
    function enterRaffle() public payable {
        // require msg.value > i_entranceFee
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender)); // enters player into player array
        // Emit an EVENT when we update a dynamic array or mapping
        emit RaffleEnter(msg.sender);
    }

    // checkUpkeep() is going t be checking to see if it is time for us to get a random number to update the recent winner and then send them all the funds

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * They look for the upKeepNeeded to return true
     * The following should be true to return true
     * 1. Our time interval should have passed
     * 2. The lottery should have atleast 1 player and have some ETH
     * 3. Our subscription is funded with LINK
     * 4. The lottery should be in an open state
     */

    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = (RaffleState.OPEN == s_raffleState); // isOpen will be true if s_raffleState is OPEN
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval); // 1st condition : Our time interval should have passed
        bool hasPlayers = (s_players.length > 0); // 2nd condition : The lottery should have atleast 1 player
        bool hasBalance = (address(this).balance > 0); // and have some ETH
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance); // all of these have to be true to request a random number and it is time to end the lottery
    }

    // requestRandomWinner function
    function performUpkeep(bytes calldata /* performData */) external override {
        // external functions are cheaper than public functions
        // Request the random number
        // Do something with the random number
        // 2 transaction process
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            ); // we are passing some variables to this error so that whoever is running into this error can see why they are getting this error
        }
        s_raffleState = RaffleState.CALCULATING; // so that no one can enter the lottery while winner is being selected
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callBackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0); // resetting the players array after a round of lottery
        s_lastTimeStamp = block.timestamp; // resetting time stamp after fixed interval has passed
        //sending the money to the winner
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        //require(success)
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* View/ Pure functions */

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) { // pure function since NUM_WORDS is not being read from storage
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {  
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
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
}
