// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// For Goerli Testnet : 
//  VRF Coordinator : 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
// GasLane : 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15
// Subscription ID : 8497
// CallbackGasLimit : 500000 


// Required Functionalities 

// Players can enter the lottery by paying a certain amount
// Generate a random winner. 
// Transfer all the amount deposited to the winner.
// Make it automated generating winners and distributing funds after a fixed time. 

    error SendMoreToEnterLottery() ;
    error LotteryNotOpen() ; 
    error Lottery_UpKeepNotNeeded();
    error Raffle__TransferFailed();

contract Lottery is VRFConsumerBaseV2 {

    

    // to check the state of lottery open is for entrance in lottery 
    // this enum is  just a type to check state of the lottery 

    //we can also use bool here but in terms of readability enum is better than bool 
    enum StateLottery {
        open ,  
        Calculating 
    }

    StateLottery public stateLottery ;  // statte Lottery is  a state variable means it is expensive 
    uint256 public immutable i_entryFee;   // entryFee is  a cheap vaiable immutable is cheaper than storage 
    address payable[] public players ;
    uint256 public immutable i_interval ;
    uint256 public s_lastTimeStamp ; 
    VRFCoordinatorV2Interface public immutable i_vrfCoordinator ;
    bytes32 public i_gasLane ; 
    uint64  public i_subscriptionId ; 
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    address public s_recentWinner ;



    event LotteryEnter(address indexed player) ;
    event RequestedLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed player); 


    constructor(uint256 entryFee, uint256 interval , address vrfCoordinatorV2 , bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entryFee = entryFee;
        i_interval = interval ; 
         s_lastTimeStamp = block.timestamp ; 
         i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2); 
         i_gasLane = gasLane ; 
         i_subscriptionId = subscriptionId ; 
         i_callbackGasLimit = callbackGasLimit ; 
         



    }

    function enterLottery() external payable {
        if (msg.value < i_entryFee) {
            revert SendMoreToEnterLottery() ;

        }

        if(stateLottery != StateLottery.open) {
            revert LotteryNotOpen() ;

        }

        players.push(payable(msg.sender)) ;
        emit LotteryEnter(msg.sender) ; 


    }

    // A function to tell the lottery at the time of deciding a new winner 

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
       
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )

        {
        bool isOpen = StateLottery.open == stateLottery;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function  performUpKeep( bytes calldata ) external {
        (bool upkeepNeeded, ) = checkUpkeep(""); 

        if(!upkeepNeeded){
            revert Lottery_UpKeepNotNeeded();

        }

        stateLottery = StateLottery.Calculating ;
          uint256 requestId = i_vrfCoordinator.requestRandomWords(i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS);

          emit RequestedLotteryWinner(requestId);


    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % players.length;
        address payable recentWinner = players[indexOfWinner];
        s_recentWinner = recentWinner ; 
        players = new address payable[](0);
        stateLottery = StateLottery.open;
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");

         if (!success) {
            revert Raffle__TransferFailed();
        }

        emit WinnerPicked(recentWinner);


    }

}
