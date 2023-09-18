/*
   - Enter the raffle(by paying some amount)
   - Pick a random entry (verifiably random )
   - Winner to be selected every X minutes (completely automated)
   - Chainlink Oracle -> Random Number(chainlink VRF) and event-driven execution of smart contract(chainlink keepers)
 */

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//Imports
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);


/** @title A sample Raffle Contract
  * @author Aditya Kumar Singh
  * @notice This contract is for creating an untamperable decentralized smart contract powered raffle.
  * @dev This implements chainlink VRF v2 and chainlink Keepers. 
 */
contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    //Type Declarations
    enum RaffleState {
        OPEN,
        CALCULATING
    } //uint256 0 = OPEN AND 1 = CALCULATING

    // State Variables
    uint256 private immutable i_entranceFees;
    address payable[] private s_players; //making the address payable as we need to pay one of these address if one of these players win.   //storage variables.
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    //Raffle Variables
    address payable private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    //Events
    event RaffleEnter(address indexed player);
    event RequestRaffleWinner(uint256 indexed requestId);
    event winnerPicked(address indexed winner);

    //Constructor
    constructor(
        address vrfCordinatorV2,    //contract address -> need to also deploy a mock for this.
        uint256 _entranceFees,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCordinatorV2) {
        //vrfCordinatorV2 is the address of the VRFConsumerBaseV2 contract which gives us the random number.
        i_entranceFees = _entranceFees;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCordinatorV2); //this creates us a contract with which we can interact with.
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        // s_raffleState = RaffleState(0);
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp; ///block.timestamp is a globally avaible variable.
        i_interval = interval;
    } // end constructor

    function enterRaffle() public payable {
        // enter the raffle
        if (msg.value < i_entranceFees) {
            revert Raffle__NotEnoughETHEntered(); //checking to see if the entered amount is enough
        }
        if (s_raffleState == RaffleState.CALCULATING) {
            revert Raffle__NotOpen(); //checking to see if the raffle is still calculating.
        }
        s_players.push(payable(msg.sender)); //as the array is payable, we need to push the address in the array.
        //Whenever a player enters the raffle, we need to emit the event.
        //Name the events with the function names reversed.
        emit RaffleEnter(msg.sender); //emiting the event when a player enters the raffle.
    }

    //This function will be called by the chainlink keepers to pick a random player in a constant interval.
    //external functions are cheaper than public functions as our own contract can't call it.

    //steps:-
    //request the random number   --> Transaction Number 1
    //once we get it do something with it.  ---> Transaction Number 2
    //2 transaction process

    /**
     * @dev This is the function that the chainlink keeper nodes will call
     * They look for the `upkeepNeeded` to return true, then, they execute the performUpkeep function.
     * The following should return true in order to return true.
     * 1. Our time interval should have passed
     * 2. The raffle should have at least 1 player, and have some ETH to award.
     * 3. Our subscription is funded with LINK.
     * 4. The raffle should be in "open" state, while we're waiting for our random number we are in "closed" or "calculating" state.
     */

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = (address(this).balance > 0);
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance); //This will automatically get returned.
    }

    function performUpkeep(
        bytes calldata /* *performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep(""); 
        if(!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //maximum gas price that you're willing to pay for the getting the random number.
            i_subscriptionId, // This is the subscription Id that this contract uses to fund this requests.
            REQUEST_CONFIRMATIONS, //How many confirmations should the chainlink node should wait before responding with the random number.
            i_callbackGasLimit, //The gasLimit for fulfillRandomWords callback function .
            NUM_WORDS //number of random words that wee need.
        );
        //This emmission of event is redundant as the requestRandomWords function will emit the event and has requestId as its second parameter. 
        emit RequestRaffleWinner(requestId); //emiting the event when we get a requestId.
    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        //we need to pick a random player from the array.
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[winnerIndex];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0); //resetting the players array.
        s_lastTimeStamp = block.timestamp; //updating the lastTimeStamp.
        //sending the entire contract balance to recent winner.
        (bool callSuccess, ) = recentWinner.call{value: address(this).balance}("");
        //require(callSuccess, "Failed to send the entire contract balance to the winner");
        if (!callSuccess) {
            revert Raffle__TransferFailed();
        }
        emit winnerPicked(recentWinner); //emiting an event when we get a winner.
    }

    //view or pure functions
    function getEntranceFees() public view returns (uint256) {
        return i_entranceFees;
    }

    function getPlayer(uint256 _index) public view returns (address) {
        return s_players[_index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState){
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256){
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256){
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns(uint256){
        return s_lastTimeStamp;
    }
    
    function getRequestConfirmations() public pure returns(uint256){
        return REQUEST_CONFIRMATIONS;
    }
    function getInterval() public view returns(uint256){
        return i_interval;
    }
}

