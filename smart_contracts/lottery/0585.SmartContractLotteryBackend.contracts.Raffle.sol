// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//imports 
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";


// Errors
error Raffle__NotEnoughEth();
error Raffle__TransactionFailed();
error Raffle__NotOpen();
error Raffle__NoUpKeepNeeded(uint256 currentBalance,uint256 numPlayers,uint256 currRaffleState);

contract Raffle is VRFConsumerBaseV2,AutomationCompatibleInterface {
    // Type Declarations
    enum RaffleState{
        Open,calculating
    }
    // State Variables
    uint32 private constant NUM_WORDS = 1;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callBackGasLimit;

    //Lottery Variables
    uint256 private immutable i_entranceFee;
    address payable [] private s_players;
    address payable private s_recentWinner;
    RaffleState s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;


    //Events
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address winner);

    //Constructor
    constructor(address vrfCoordinatorV2Address,
    uint256 entranceFee,
    bytes32 gasLane,
    uint64 subscriptionId,
    uint32 callBackGasLimit,
    uint256 interval) VRFConsumerBaseV2(vrfCoordinatorV2Address){
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2Address);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callBackGasLimit;
        s_raffleState = RaffleState.Open;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }
    // Allow users to participate , i.e allow them to send ether
    function enterRaffle() public payable{
        if(msg.value < i_entranceFee){
            revert Raffle__NotEnoughEth();
        }
        if(s_raffleState != RaffleState.Open){
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }
    // pick a random winner from the players
    // The following should be true in order for upKeepNeeded to be true:
    // 1. The time Interval should have been passed
    // 2. there should be atleast 2 players
    // 3. There should be some eth
    // 4. our subscription should be funded with LINK
    function checkUpkeep(bytes memory /*checkData*/)public view override
        returns (bool upKeepNeeded, bytes memory /* performData */){
            bool isOpen = (s_raffleState == RaffleState.Open);
            bool hasTimePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
            bool hasPlayers = s_players.length >= 1;
            bool isBalance = address(this).balance > 0;
            upKeepNeeded = (isOpen && hasTimePassed && hasPlayers && isBalance);

    }
    function performUpkeep(bytes calldata /*performData*/) external override{
        (bool upKeepNeeded,) = checkUpkeep("");
        if(!upKeepNeeded){
            revert Raffle__NoUpKeepNeeded(address(this).balance,s_players.length,uint256(s_raffleState));
        }
        s_raffleState = RaffleState.calculating;
         uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callBackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }
    function fulfillRandomWords(uint256,/*requestId*/
    uint256 [] memory randomWords) internal override{
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_recentWinner = winner;
        s_raffleState = RaffleState.Open;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success,) = winner.call{value : address(this).balance}("");
        if(!success){
            revert Raffle__TransactionFailed();
        }
        emit WinnerPicked(winner);
    }
    // pick a Winner automatically after X minutes
    // view/pure functions
    function getEntranceFee()public view returns(uint256){
        return i_entranceFee;
    }
    function getPlayer(uint256 index) public view returns(address){
        return s_players[index];
    }
    function getRecentWinner() public view returns(address){
        return s_recentWinner;
    }
    function getNumWords()public pure returns(uint256){
        return NUM_WORDS;
    }
    function getNumPlayers()public view returns(uint256){
        return s_players.length;
    }
    function getLatestTimeStamp()public view returns(uint256){
        return s_lastTimeStamp;
    }
    function getInterval()public view returns(uint256){
        return i_interval;
    }
    function getRaffleState()public view returns(RaffleState){
        return s_raffleState;
    }
}