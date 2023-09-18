// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughEthEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);


/**@title A sample Raffle Contract
 * @author Bhasker Rai
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */



contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {

    /* Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    } //uint256 OPEN = 0, uint256 CALCULATING = 1


    /* Sate Variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;                    //Hash value which is maximum gas price you are willing to pay
    uint64 private immutable i_subscriptionId;             //The subscription ID that this contract uses for funding requests
    uint16 private constant REQUEST_CONFIRMATIONS = 3;    //How many confirmations the Chainlink node should wait before responding. The longer the node waits, the more secure the random value is.
    uint32 private immutable i_callbackGasLimit;         //The limit for how much gas to use for the callback request to your contract’s fulfillRandomWords function.
    uint32 private constant NUM_WORDS = 1;              //How many random values to request

    //Lottery Variables
    address private s_recentWinner;
    RaffleState private s_raffleState; //true
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;


    /* Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /* Functions */

    constructor(
        address vrfCoordinatorV2, //this is a contract, so we'll have create a mock and deploy it.
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
        i_interval = interval;
    }

    
    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthEntered();
        }

        if (s_raffleState != RaffleState.OPEN){
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));

        //Emit an event when we update a dynamic array or mapping
        //note: name events with the function name reversed
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev This is the function that Chainlink Automation nodes call
     * they look for `upkeepNeeded` to return true
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(bytes memory /*checkData*/ ) 
    public override returns (bool upkeepNeeded, bytes memory /*performanceData*/) {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = ((s_players.length > 0));
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(bytes calldata /* performData */) external override{
        //external functions are little bit cheaper than public functions.
        //chainlink VRF is two-transactions process.

        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, 
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256 /*requestId */, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner; 
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0); //after the winner is chosen, the players array is reset.
        s_lastTimeStamp = block.timestamp;

        (bool success, ) = recentWinner.call{ value: address(this).balance }("");

        if (!success) {
            revert Raffle__TransferFailed();
        }

        emit WinnerPicked(recentWinner);
    }



    /* View / Pure Functions */

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRecentWinner() public view returns(address) {
        return s_recentWinner; 
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRaffleState() public view returns(RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns(uint256) { //since NUM_WORDS is a contant, and contants reside in bytecode and not in storage, therefore we can use 'pure' instead of 'view'.
        return NUM_WORDS;
    }

    function getNumOfPlayers() public view returns(uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns(uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmation() public pure returns(uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns(uint256){
        return i_interval;
    }
}
