//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.18;
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

error Lottery__NotEnoughETHEntered();
error Lottery__TransferFailed();
error Lotter__NotOpen();
error Lottery__UpkeepNotNeeded(uint256 currentBalance,uint256 numPlayers,uint256 lotteryState);
contract Lottery is VRFConsumerBaseV2,AutomationCompatibleInterface{
   //Enums 
   enum LotteryState {
    OPEN,
    CALCULATING
   }
   
   
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
     VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
      bytes32 private  immutable i_gasLane;
       uint64 private immutable i_subscriptionId;
       uint32 private immutable i_callbackGasLimit;
       uint16 private constant REQUEST_CONFIRMATIONS = 3;
       uint32 private constant NUM_WORDS = 1;

       //Lottery Variables
       address private s_recentWinner;
       LotteryState private s_lotteryState;
        uint256 private s_lastTimeStamp;
        uint256 private immutable i_interval;

// Events
event Lotteryenter(address indexed player);
event RequestedLotteryWinner(uint256 indexed requestId);
event WinnerPicked(address indexed winner);
    constructor(address vrfCoordinatorV2 ,
    uint256 entranceFee,
    bytes32 i_gasLane,
    uint64 i_subscriptionId,
    uint32 callbackGasLimit,
    uint256 interval
    ) 
    VRFConsumerBaseV2(vrfCoordinatorV2){
        i_entranceFee = i_entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timeStamp;
        i_interval = interval;
    }

function enterLottery() public payable{
if(msg.value < i_entranceFee){
    revert Lottery__NotEnoughETHEntered();
}
if(s_raffleState != RaffleState.OPEN){
    revert Lottery__NotOpen();
}
s_players.push(payable(msg.sender));
emit Lotteryenter(msg.sender);
}

 function checkUpkeep(
        bytes memory /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = (LotteryState.OPEN == s_lotteryState);
        bool timePassed = ((block.timestamp - lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balanace > 0;
          upkeepNeeded =(isOpen && timePassed && hasPlayers && hasBalance);
         }

function performUpkeep(bytes calldata /* performData */) external returns (uint256 requestId){
   (bool upkeepNeeded, ) = checkUpkeep("");
   if(!upkeepNeeded){
    revert Lottery__UpkeepNotNeeded(address(this).balanace,s_players.length,uint256(s_lotteryState));
   } 
   
    s_lotteryState = LotteryState.CALCULATING;
   requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedLotteryWinner(requestId);
}

function fullfillRandomWords(uint256 requestId,uint256[] memory randomWords) internal override{
    uint256 indexOfRandomWinner = randomWords % s_players.length;
    address payable recentWinner = s_players[indexOfRandomWinner];
    s_recentWinner = recentWinner;
    s_lotterState = LotteryState.OPEN;
    s_players = new address payable[](0);
    s_lastTimeStamp = block.timestamp;
    (bool success,) = recentWinner.call{value: address(this).balance}(""); 
    if(!success){
        revert Lottery__TransferFailed();
    }
    emit WinnerPicked(recentWinner);
    }

function getEntranceFee()public view returns(uint256){
    return i_entranceFee;
}
fucntion getPlayer(uint256 index) public view returns(address){
    retrun s_players[index];
}
function getRecentWinner() public view returns(address){
    return s_recentWinner;
}
function getLotteryState() public view returns(LotteryState){
    return s_lotteryState;
}
function getNumWords() public pure returns(uint256){
    return NUM_WORDS;
}
function getPlayers() public view returns(uint256){
    return s_players.length;
}
function getLatestTimeStamp() public view returns(uint256){
    return s_latestTimeStamp;
}
function getRequestConfirmation() public pure returns(uint256){
    return REQUEST_CONFIRMATIONS;
}
}