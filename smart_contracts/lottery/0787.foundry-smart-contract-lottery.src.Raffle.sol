//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


/**
 * @title Raffle contract
 * @author Marcxime Prosper
 * @notice This contract is used to create a raffle
 * @dev Implements Chainlink VRFv2 for random number generation
 */

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
//import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";


contract Raffle is VRFConsumerBaseV2{
    error Raffle__NotEnoughEthToEnterRaffle();
    error Raffle__NotEnoughTimePassed();
    error Raffle__NotPayed();
    error Raffle__RaffleNotOpen();

    //Types
    enum State {
        Open,
        Closed
    }

    //state variables
    State private s_raffleState;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUMWORDS = 1; //number of random words to return
    address private s_recentWinner;
  

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    /**@dev duration of the lottery in seconds */
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    VRFCoordinatorV2Interface private immutable i_COORDINATOR;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    

    event EnteredRaffle(
        address indexed player
    );
    event WinnerPicked(
        address indexed winner
    );
    event RequestedRaffleWinner(uint256 indexed requestId);
    //what are some functions we need?
    //1. buy tickets
    //2. pick winner
    //3. get balance

    //Constructor
    constructor (uint256 entranceFee,
     uint256 interval,
      address coordinator,
       bytes32 keyHash,
        uint64 subscriptionId,
         uint32 callbackGasLimit)
    VRFConsumerBaseV2(coordinator) {    
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_COORDINATOR = VRFCoordinatorV2Interface(coordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() external payable {
        if(msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthToEnterRaffle();
        }
        if(s_raffleState != State.Open) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev Function that the chainlink automation nodes call   
     * to see if it's time to perform an upkeep. 
     */
    function checkUpKeep(bytes memory /*checkData*/)
    public
    view
    returns(bool upKeepNeeded, bytes memory /*performData*/) {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen =   (Raffle.State.Open == s_raffleState);
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upKeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upKeepNeeded, "0x0");
    }


    //get random number 
    //use random number to get a winner
    //be automatically called   
    function performUpKeep(bytes calldata /*performData*/) external {
        (bool upKeepNeeded,) = checkUpKeep("");  
        if(!upKeepNeeded) {
            revert Raffle__NotEnoughTimePassed();
            }  
        s_raffleState = State.Closed;
        /**@dev get random number */
           uint256 requestId = i_COORDINATOR.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUMWORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256 requestId,
    uint256[] memory randomWords) internal override {
        uint256 indexOfWinner =(randomWords[0]) % (s_players.length);
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = State.Open;

        s_players = new address payable[](0); //resetting the players array
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = winner.call{value: address(this).balance}("");
        if(!success) {
            revert Raffle__NotPayed();
        }

        emit WinnerPicked(winner);
    }

    //View/Pure Getter Functions

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() public view returns(State) {
        return s_raffleState;
    }
    function getNumberOfPlayers() public view returns(uint256) {
        return s_players.length;
    }
    function getSpecificPlayer(uint256 index) public view returns(address) {
        return s_players[index];
    }
    function getRecentWinner() public view returns(address) {
        return s_recentWinner;
    }
    function getLengthOfPlayersArray() public view returns(uint256) {
        return s_players.length;
    }
    function getLastTimestamp() public view returns(uint256) {
        return s_lastTimeStamp;
    }
}