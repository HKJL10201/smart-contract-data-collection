/** 
 * Enter the lottery ,(paying fees)
 * Pick random winner (chainLink VRF, transparent and verifiable )
 * Slection process autamated;
 * ChainLink Oracle -> randomness, automation --> ChainLink Keeper;
 * 
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";


/** error */
error Raffle__notEnoughFunds();
error Raffle__TransferFailed();
error Raffle__notOpen(); 
error Raffle__upKeepNotNeeded(uint256 currentBalance, uint256 numOfPlayer, uint256 raffleState);

/**@title A sample Raffle Contract
 * @author Cong
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface{
    // type 
    enum RaffleState {
        open,
        calculating
    }

    //State variable 
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; 
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS =  3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    //lottery
    address  private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;



    /*Events */
    event RaffleEnter (address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event winnerPicked (address indexed winner);


    constructor (address vrfCoodinatorV2,
    uint256 entranceFee,
    uint256 interval,
    bytes32 gasLane,
    uint64 subscriptionId,
    uint32 callbackGasLimit
    )VRFConsumerBaseV2(vrfCoodinatorV2){
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoodinatorV2); 
        i_gasLane = gasLane; 
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.open;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;

    }
    
    function enterRaffle() public payable{
        if (msg.value < i_entranceFee)  {
            revert Raffle__notEnoughFunds();
        }
        if (s_raffleState != RaffleState.open) {
            revert Raffle__notOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    /**
     * function chainLink call, check bool
     * time interval 
     * player != 0 and is_qualified
     * subscription funded with link
     * lottery open
     */

    function checkUpkeep(bytes memory /*checkData */) public view override returns(bool upKeepNeeded, bytes memory /* performe data?*/) {
        bool is_Open = (RaffleState.open == s_raffleState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp)> i_interval);
        bool has_Player = (s_players.length > 0);
        bool has_Balance = (address(this).balance > 0);
        // blocktime diff > interval; 
        upKeepNeeded = (is_Open && timePassed && has_Player && has_Balance );
         
    }
    
 
    function performUpkeep (bytes calldata /* performe data */) external override {
        //request the random num
        //pick winner
        //execute 
        //VRF 2 transaction process
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (! upKeepNeeded) {
            revert Raffle__upKeepNotNeeded(address(this).balance, s_players.length,
            uint256 (s_raffleState));
        }
        s_raffleState = RaffleState.calculating;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS

        );
        emit RequestedRaffleWinner(requestId);
        /**
         * i_gasLane
         * uint32 callbackGasLimit
         * requestConfirmations,
         * numWords
         */
        
    }
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.open;
        s_players = new address payable[] (0);
        s_lastTimeStamp = block.timestamp; 

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(success, "Transfer failed");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit winnerPicked(recentWinner);
    }
    /* view pure functions*/
    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getWinner() public view returns(address) {
        return s_recentWinner; 
    }

    function getEntranceFee() public view returns(uint256) {
        return i_entranceFee;
    }


    function getNumWord() public pure returns (uint) {
        return NUM_WORDS;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }


    function getNumberOfPlayers() public view returns(uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns(uint256) {
        return s_lastTimeStamp;
    }  

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
      
   
}