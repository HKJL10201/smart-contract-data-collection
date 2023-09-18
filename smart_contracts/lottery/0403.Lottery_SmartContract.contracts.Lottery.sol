// SPDX-License-Identifier: MIT
//create lottery contract

/**
 *enter the lottery by paying some amount
 *pick a random winner from those who enetered the in the lottery
 *winner will be choosen among those who have entered in lottery in every x unit time (automated no intervention from the any one)
 *
 * 
 * to get random winner we wil use 
 * Chainlink Oracle --> Randomness, Automated Execution(to select winner after certain time automatic event trigger required) Chainlink keeper for this
 */

//main point to note from this 
/**
 *     // external functions are cheaper than public functions and cannot be called by own contact
 * since in getNumWords we return constant so we can use pure insted of view since we are not reading from storage
 */

pragma solidity ^0.8.17;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol';

// errors
error For_Lottery_NotEnoughETH();
error Lottery_winnerTransaction_Failed();
error Lottery_Not_Open();
error Lottery_Not_UpkeepNeeded(uint256 currentBalance, uint256 numPlayers, uint256 LotteryState);


contract Lottery is VRFConsumerBaseV2,KeeperCompatibleInterface {
    // enum should e declared first 
    //type decration
    enum LotteryState {
        OPEN,
        CAlCULATING
    }
    /****
       * @title lottery contract
       * @author Abhishek Yadav
       * @notice decentralized smart contract for lottery system
       * @dev used Chainlink vrf and Chainlink keepers
      */
    

    //state variable
    /* i_entranceFee amount that should paid to enter in the lottery 
    immutable becuse more gas efficient than storage
     */
        uint256 private immutable i_entranceFee;
    /**
     * s_players store the all players those who have enetered in the lottery contest
     * payable address so that we can send amount to winner
     * storage variable we will change its value
     */
        address payable[] private s_players;
        VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
        bytes32 private immutable i_gasLane;
        uint16 private constant REQUEST_CONFIORMATIONS = 3;
        uint64 private immutable i_subscriptionId;
        uint32 private immutable i_callbackGasLimit;
        uint16 private immutable NUM_WORDS = 1;
        

        address payable private s_recentWinner;
        LotteryState s_lotteryState = LotteryState.OPEN;
        uint256 private s_lastTimeStamp;
        uint256 private immutable i_interval;

        // creating events
    event LotteryEnter(
        address indexed player
    );
    event PickedWinner(
        address indexed winner
    );
/**
 *  vrfCoordinatorV2Address is address of the contarct which verifies random number
 */
    constructor(
        address vrfCoordinatorV2Address,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
        ) VRFConsumerBaseV2(vrfCoordinatorV2Address) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2Address);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    function enterLottery() public payable {


        //check if lottery is open to enter player
        if(s_lotteryState != LotteryState.OPEN){
            revert Lottery_Not_Open();
        }

        //require(msg.value > i_entranceFee, "not enough eth") // not gas efficient
        if(msg.value < i_entranceFee){
            revert For_Lottery_NotEnoughETH();
        }
        
        // type cast msg.sender to payable address type
        s_players.push(payable(msg.sender));
        // event emitted when when we update a dynamic storage array or mapping
        emit LotteryEnter(msg.sender);
    }


// chainlink keepers
/**
 * @dev this function called by chainlink keeper nodes call
 * they look foor ' upkeepNeeded ' to true
 * for upkeepNeeded to be true these must fulfilled
 * 1. Criteria specified by contract should be fulfilled (in this case time interval)
 * 2. it should have 1 player and some eth
 * our subscription should have link toke
 * Since we want to make sure no player can enter when we are requesting random number
 * so we need to make some state variables for the lottery is open deciding winner closed
*/
function checkUpkeep(
    bytes memory
    ) public 
    override   
    returns (
        bool upkeepNeeded,
        bytes memory /**performData */
    ) {
    bool isOpen = (LotteryState.OPEN == s_lotteryState);
    bool interval = ((block.timestamp - s_lastTimeStamp) > i_interval);
    bool havePlayers = (s_players.length > 1);
    bool isBalance = address(this).balance > 0;
    upkeepNeeded = (isOpen && interval && havePlayers && isBalance);
}
    // pick random 
    // chainlink VRF

// if checkUpKeep is true call performUpkeep
// we can either make requestRandomness function to performUpkeep or call from performUpkeep
    function performUpkeep(bytes calldata) external override{
// update state of lottery 
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded){
            revert Lottery_Not_UpkeepNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
                );
        }
        s_lotteryState = LotteryState.CAlCULATING;
        //in order to get a random number 
        //1. Request random number
        //2. Once we gwt do something 

        //requestRandomWords return requestId
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //maximum gas that can be paid to get random number
            i_subscriptionId,
            REQUEST_CONFIORMATIONS, // number of block confirmations before sending the random number
            i_callbackGasLimit, // gas to be used for callback fulfillRandomWords
            NUM_WORDS  // how many random number you wants 
        );
        
    }
    // we need to implement the fulfillRandomWords because vrfCoordinator knows about it sends random number to it 
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) 
    internal 
    override{
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winnerAddress = s_players[winnerIndex];
        s_recentWinner = winnerAddress;
        //once winner is choosen reset the player array
        s_players = new address payable[](0);
        //now update thye last time stamp with current one 
        s_lastTimeStamp = block.timestamp;
        //once winner make loottery state to open
        s_lotteryState = LotteryState.OPEN;

        (bool success, ) = s_recentWinner.call{value:address(this).balance}("");
        if(!success){
            revert Lottery_winnerTransaction_Failed();
        }
        emit PickedWinner(s_recentWinner);
    }
    function getrecentWinner() public view returns(address){
        return s_recentWinner;
    }
    function getLotteryEntranceFee() public view  returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns(address){
        return s_players[index];
    }
    function getLotteryState() public view returns(LotteryState){
        return s_lotteryState;
    }
    function getNumWords() public pure returns(uint256){
        return NUM_WORDS;
    }
    function getNumberOfPlayers() public view returns(uint256){
        return s_players.length;
    }
    function getLastTimeStamp() public view returns(uint256){
        return s_lastTimeStamp;
    }
}