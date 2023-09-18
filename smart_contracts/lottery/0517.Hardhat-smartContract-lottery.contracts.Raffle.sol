// Enter lottery paying some amount
// Pick Random Winner (Verifiably Random)
// Winner to be selected after every X minutes
//chainlink oracle-> Randomness , Automated Execution(Chainlink Keeper)
// Raffle

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol"; 

error Raffle__NotEnoughEthEntered();
error Raffle__TransferFailed() ;
error Raffle__NotOpen() ;
error Raffle__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 totalPlayers,
    uint256 raffleState
    ) ; 

/**
    * @title A sample Raffle Contract
    * @author Mudit Jain
    * @notice This contract is for creating an untamperable decentralized smart Contract
    * @dev this contract implements Chainlink VRF2 and Chainlink Keepers 
 */ 


contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
   
   /**Type declarations */
   enum RaffleState{
       OPEN,
       CALCULATING
   }
   
    /**State  */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane ;
    uint64 private immutable i_subscriptionId ;
    uint32 private immutable i_callbackGasLimit ; 
    uint16 private constant REQUEST_CONFIRMATIONS = 3 ; 
    uint32 private constant NUM_WORDS = 1 ; 
    //number of random words wanted
    
    //Lottery variables 
    address private s_recentWinner ; 
    RaffleState private s_raffleState ;
    uint256 private s_lastTimeStamp ; 
    uint256 private immutable i_interval ;

    /**Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId); 
    event WinnerPicked(address indexed winner); 

    constructor(
        address _VRFCoordinatorv2,
        uint256 _entraceFee, 
        bytes32 gasLane, 
        uint64 subscriptionId, 
        uint32 callbackGasLimit,
        uint256 interval
        )
        VRFConsumerBaseV2(_VRFCoordinatorv2)
    {
        i_entranceFee = _entraceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_VRFCoordinatorv2);
        i_gasLane = gasLane ; 
        i_subscriptionId = subscriptionId ;
        i_callbackGasLimit = callbackGasLimit ; 
        s_raffleState = RaffleState.OPEN ;
        s_lastTimeStamp = block.timestamp ; 
        i_interval = interval ;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthEntered();
        }
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__NotOpen(); 
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    /**
     *@dev This is the function that chainlink keeper nodes call
     * to check if 'upkeepNeeded' is true  
     * conditons for upkeep to be true
     * 1.passage of time passed 
     * 2.lottery should have 1 player atleast and some ETH
     * 3.Our subscription should funded with LINK
     * 4.The lottery should be in an "open state" 
     */
    function checkUpkeep(
        bytes memory /*checkData*/) 
        public
        override
        returns(
            bool upkeepNeeded, 
            bytes memory /* performData */
        )
        {
            bool isOpen = ( s_raffleState == RaffleState.OPEN ) ; 
            bool timePassed = ( (block.timestamp - s_lastTimeStamp ) > i_interval ) ;
            bool hasPlayers = ( s_players.length >= 1 ) ;
            bool hasBalance = ( address(this).balance > 0 );
            upkeepNeeded = ( isOpen && timePassed && hasPlayers && hasBalance ) ; 
    }


    function performUpkeep(
        bytes calldata /* performData */
    ) public override {
        // Request random winner
        // Once we get it , do something with it
        // 2 transaction process
        // Hacker cannot hack by repeatedly calling same func
        
        (bool upkeepNeeded , ) = checkUpkeep(""); 
        if(!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
                ) ; 
        }
        s_raffleState = RaffleState.CALCULATING ; 
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //gasLane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        //this is redundant !! since vrfCoordinator already emits an event
        emit RequestedRaffleWinner(requestId) ;
    }

    function fulfillRandomWords(
        uint256 /*requestId*/, 
        uint256[] memory randomWords)
        internal
        override
    {
        uint256 indexOfWinner = randomWords[0] % (s_players.length) ;
        address payable recentWinner = s_players[indexOfWinner] ;
        s_recentWinner = recentWinner ;
        s_raffleState = RaffleState.OPEN ; 
        s_players = new address payable [](0)  ;
        s_lastTimeStamp = block.timestamp ; 
        (bool success, ) = recentWinner.call{value: address(this).balance}("");  
        if(!success){
            revert Raffle__TransferFailed() ; 
        }

        emit WinnerPicked(recentWinner) ;
    }

    /* view /pure functions */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee ;
    }

    function getPlayers(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns(address){
        return s_recentWinner ; 
    }

    function getRaffleState() public view returns(RaffleState){
        return s_raffleState ; 
    }

    function getNumWords() public pure returns(uint256){
        return NUM_WORDS; 
    }
    //since NUM_WORDS is immutable (not in storage) so pure can be used  

    function getNumberOfPlayers() public view returns(uint256){
        return s_players.length ; 
    }

    function getLatestTimestamp() public view returns(uint256){
        return s_lastTimeStamp ; 
    }

    function getRequestConfirmations() public pure returns(uint16){
        return REQUEST_CONFIRMATIONS ; 
    }

    function getInterval() public view returns(uint256){
        return i_interval ; 
    }

    function getSubscriptionId() public view returns(uint128){
        return i_subscriptionId ; 
    }
        
}
