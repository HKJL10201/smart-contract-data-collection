// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
/* Imports */
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
/* Errors */
error Lottery__NotEnoughETH();
error Lottery__TransferFailed();
error Lottery__NotOpen();
error Lottery__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 lotteryState);

/**
 * @title Lottery contract
 * @author 1cf
 * @notice This contract creates a descentralized and automated lottery 
 * which lets players to enter the lottery by sending an amount of ether.
 * @dev This contract implements Chainlink VRF v2 and Chainlink Keepers.
 */

contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface{
    /* Types */
    enum LotteryState {
        OPEN,
        PENDING
    }
    /* State variables */
    uint256  private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    // Lottery variables
    address private s_recentWinner;
    LotteryState private s_lotteryState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_timeInterval;
    
    /* Events */
    event LotteryEnter(address indexed player);
    event RequestLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /* Constructor */
    constructor (
        address vrfCoordinatorV2,
        uint256 entranceFee, 
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 timeInterval
        ) VRFConsumerBaseV2(vrfCoordinatorV2){

        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_timeInterval = timeInterval;
        
    }
    function enterLottery() public payable {
        if(msg.value < i_entranceFee){
            revert Lottery__NotEnoughETH();
        }
        if(s_lotteryState != LotteryState.OPEN){
            revert Lottery__NotOpen();
        }
        s_players.push(payable(msg.sender));
        // Emit the event when the players array is updated
        emit LotteryEnter(msg.sender);
    }

    /**
     * @dev Function called by the Chainlink nodes.
     * To return true and get a random winner the following conditions need to be true:
     * 1: The time interval has to have passed.
     * 2: The Lottery contract has to have some ETH.
     * 3: There should be at least 1 player.
     * 4: The suscription has to be funded with some LINK.
     * 5: The lottery has to be in an "open" state.
     */
    
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
         bool isOpen = LotteryState.OPEN == s_lotteryState;
         bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_timeInterval);
         bool hasPlayers = s_players.length > 0;
         bool hasBalance = address(this).balance > 0;
         upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
         return(upkeepNeeded, "0x0");
    }
    
    function performUpkeep( 
        bytes calldata /* perfomData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded){
            revert Lottery__UpkeepNotNeeded(
                address(this).balance, 
                s_players.length, 
                uint256(s_lotteryState)
                );
        }
        // Update lottery state
        s_lotteryState = LotteryState.PENDING;
        // Get a random number
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestLotteryWinner(requestId);
    }
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
        ) internal override {

        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        // Update lottery state to OPEN
        s_lotteryState = LotteryState.OPEN;
        // Empty players array
        s_players = new address payable[](0);
        // Reset timestamp
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if(!success){revert Lottery__TransferFailed();}
        emit WinnerPicked(recentWinner);
    }


    /* View / Pure functions */
    function getEntranceFee() public view returns (uint256){
        return i_entranceFee;
    }
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }
    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }
    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }
    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }
    function getNumPlayers() public view returns (uint256) {
        return s_players.length;
    }
    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }
    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }
    function getTimeInterval() public view returns (uint256) {
        return i_timeInterval;
    }
    function getCallbackGasLimit() public view returns (uint256) {
        return i_callbackGasLimit;
    }
}