// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7 ;


//enter the lottery -> pay some amount 
//Pick a verifiable random winner
//winner to be selected every x min, year,months ... automated 
//need to use chainlink Oracle -> randomness, Automated, Execution

error Lottery_NotEnoughEthEntered(); 
error Lottery_TransferedFailed();
error Raffle__NotOpen();
error Raffle__UPkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

/** @title An Raffle Contract
    @author Sydney Sanders 
    @notice This contract is creating a untamperable decentralized smart contract
    @dev This implements chainlink VRF v2 and chainlink keepers

 */

contract Lottery is VRFConsumerBaseV2 ,KeeperCompatibleInterface { 
    // Types 
    enum RaffleState { 
        OPEN, //0 = open
        CALCULATING //1 = calculating
    }


    /**State Variables */
    uint256 private immutable i_entryFee;  
    //keep track of players whom enter
    address payable[] private  s_players;
    //work with vrfcoordinator 
    //good practice, espeically if we setting one time.
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; 
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionID;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;


    //lottery vars 
    address private s_recentWinner;
    uint256 private s_lastTimeStamp; 
    uint256 private immutable i_interval; 
    RaffleState private s_raffleState;





    constructor(
        address vrfCoordinatorV2, 
        uint256 entryFee, 
        bytes32 keyHash,
        uint64 subscriptionID,
        uint32 callbackGasLimit,
        uint256 interval
        ) 
        VRFConsumerBaseV2(vrfCoordinatorV2) { 
        i_entryFee = entryFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_keyHash = keyHash;
        i_subscriptionID = subscriptionID;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval; 
    }

    event lotteryEnter(address indexed player);
    event requestRandomWinner(uint256 indexed requestId);
    event winnerPicked(address indexed winner);
    function enterLottery() public payable { 
        //custom error which is more gas efficient
        if(msg.value < i_entryFee) { 
            revert Lottery_NotEnoughEthEntered();
        }
        if(s_raffleState != RaffleState.OPEN) { 
            revert Raffle__NotOpen();
        }
    
        //keep track of players entering the raffle.
        s_players.push(payable(msg.sender)); 
        //Emit an event when we update a dynamic array.
        emit lotteryEnter(msg.sender);

    }


  
    function fulfillRandomWords(uint256 /* requestId*/, uint256[] memory randomWords) 
    internal override
    {
        //modlus operator because uint256 can be very large number
        uint256 indexOfWinner = randomWords[0] % s_players.length; 
        address payable recentWinner = s_players[indexOfWinner];

        s_recentWinner = recentWinner;
        //open up raffle after we pick a winner 
        s_raffleState = RaffleState.OPEN;
        //reset the players array 
        s_players = new address payable[](0); 
        //reset the timeStamp
        s_lastTimeStamp = block.timestamp;
        //send money
        (bool sent,) = recentWinner.call{value: address(this).balance}(""); 
        if(!sent) { 
            revert Lottery_TransferedFailed();
        }
        emit winnerPicked(recentWinner);



    }

    /**
    @dev this is the function chainlink keeper nodes call
    *they look for 'upkeepNeeded" to return true.
    *The following should be returned true in order to return true 
    *1. Our time interval should have passed
    *2. The lottery should have at least 1 player, and have some ETH 
    *3. Our subscription is funded with LINK
    *4. Lottery should be in a open state
     */
       function checkUpkeep(bytes memory /* checkData */) public  override returns (bool upkeepNeeded, bytes memory /* performData */) {
           //only be true if raffleState is in a openState
           bool isOpen = (RaffleState.OPEN == s_raffleState);
           //check to see if enough time has passed
           bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
           //check if we have players
           bool hasPlayers = s_players.length > 0;
           bool hasBalance = address(this).balance > 0;

           bool upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance); 
           return (upkeepNeeded, "0x0");

    }

      function performUpkeep(bytes calldata /* checkData */) external override { 
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded) {
            revert Raffle__UPkeepNotNeeded(
                address(this).balance, 
                s_players.length, 
                uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING; 

        //this is also an event?
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionID,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit requestRandomWinner(requestId);



        
    }

    
    function getLotteryState() public view returns(RaffleState) { 
        return s_raffleState;
    }
    function getNumWords() public pure returns(uint256) { 
        return NUM_WORDS;
    }
    function getNumPlayers() public view returns(uint256) {
        return s_players.length;
    }
    function getLatestTimeStamp() public view returns(uint256) { 
        return s_lastTimeStamp;
    }
    function getRequestConfirmations() public pure returns(uint256) { 
        return REQUEST_CONFIRMATIONS;
    }


    function getEntryFee() public view returns(uint256) { 
        return i_entryFee;
    }

    function getPlayers(uint256 index) public view returns(address) { 
        return s_players[index];

    }
    function getRecentWinner() public view returns(address)  { 
        return s_recentWinner;
    }
    function getInterval() public view returns(uint256) { 
        return i_interval;
    }



}