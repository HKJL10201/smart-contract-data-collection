// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";



/* Error Codes */
error Lottery__SendMoreEthToEnterLottery ();
error  Lottery__TransferFailed();
error Lottery__LotteryNotOpen();
error Lottery__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 lotteryState);


contract Lottery is VRFConsumerBaseV2 {

    enum LotteryState {
        OPEN,
        CALCULATING
    }
    
    /* State Variables */
    // ChainLink Var
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gaslane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATION = 6;
    uint32 private constant NUM_WORDS = 1;

    // Lottery Vars
    uint256 private immutable i_interval;
    address private s_recentWinner;
    address payable[] private s_players;
    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimeStamp;
    LotteryState private s_lotteryState;

    // events
    event LotteryEntered(address indexed player);
    event RequestLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address recentWinner);

    constructor (
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2 (vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_subscriptionId = subscriptionId;
        i_gaslane = gasLane;
        i_interval = interval;
        i_entranceFee = entranceFee;
        i_callbackGasLimit = callbackGasLimit;  
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;

    }
    // function enterLottery
    function enterLottery () public payable {
        // Checks to perform value is greater than entrance fee
        if(msg.value < i_entranceFee) {
            revert Lottery__SendMoreEthToEnterLottery();
        }
        // Checks the state of LotteryState
        if(s_lotteryState != LotteryState.OPEN) {
            revert Lottery__LotteryNotOpen();
        }
        s_players.push(payable(msg.sender));
        // emit the event
        emit LotteryEntered(msg.sender);
    }


    /** 
    * @dev This is the fn that Chainlink keeper nodes call/execute
    * to `upkeepNeeded` to return true
    * 1. The time interval has passed between Lotteries
    * 2. The lottery is open
    * 3. The contracts has ETH
    * 4. Your subscription is funded with LINK token
    */ 
    
    function checkUpKeep (
        bytes memory /* checkData */
    ) public view  returns (
        bool upKeepNeeded,
        bytes memory /* performData */ 
    ) {
        bool isOpen = LotteryState.OPEN == s_lotteryState;
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upKeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        return (
            upKeepNeeded,
            "0x00"
        );
    }

    /**
    * @dev Once the checkUpKeep returns true, this fn is called 
    *  and the Chainlink VRF gets a random number
    */
    function performUpkeep (bytes calldata /* performData */) external  {
        (bool upKeepNeeded, ) = checkUpKeep("");
        if (!upKeepNeeded) { 
            revert Lottery__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }
        s_lotteryState = LotteryState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gaslane,
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestLotteryWinner(requestId);
    }

    // fn fulfill random words
    function fulfillRandomWords(
        uint256,  /* requestId */
        uint256[] memory randomWord
    ) internal override {
        uint256 indexOfWinner = randomWord[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable [](0);
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{ value: address(this).balance}("");
        if (!success) { 
            revert Lottery__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
        
    }

    /** Getter Functions */

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getPlayer(uint index) public view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp () public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getTotalPlayers() public view returns (uint256) {
        return s_players.length;
    }

}