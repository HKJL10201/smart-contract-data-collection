// what should we do here?

// entering the lottery is the main thing (paying some amount ofcourse)
// picking a random winner.
// winner is to be selected every X min. (automated)

// chainlink oracle ==> Randomness -- Automated Execution (chainlink keepers)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

error Lottery__NotEnoughETHEntered();
error Lottery__TransferFailed();
error Lottery__NotOpen();
error Lottery__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 lotteryState);

/**
 * @title A Lottery Contract
 * @author Mohit Kumar
 * @notice This Contract is for creating an untamperable Decentralized Smart Contract.
 * @dev This implements CHAINLINK VRF V2 and CHAINLINK KEEPERS.
 */

contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Type Declarations */
    enum LotteryState {
        OPEN,
        CALCULATING
        // 0-->OPEN,
        // 1-->CALCULATING
    }

    /* State Variables */
    // i_ ==> immutable variable (just a naming convention)
    uint256 private immutable i_entranceFee;
    // s_ ==> storage variable
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint16 private constant NUM_WORDS = 1;

    // lottery variables
    address private s_recentWinner;
    LotteryState private s_lotteryState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;
    // bool private s_isOpen; //

    /* Events */
    // indexed ==> topics
    event LotteryEnter(address indexed player);
    event RequestedLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /* Functions */
    constructor (
        address vrfCoordinatorV2, //contract
        uint256 entranceFee, 
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) public VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    // in tutorial it is enterRaffle()
    function enterLottery() public payable {
        // require(msg.value > i_entranceFee,"NOT enough ETH")
        // or
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughETHEntered();
        }
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__NotOpen();
        }
        s_players.push(payable(msg.sender));
        // emit an event when we update a dynamic array or mapping
        // naming convention for events ==> FUNCTION NAME REVERSED
        emit LotteryEnter(msg.sender);
    }

    /**
     * @dev this is the function that chainlink keeper nodes call
     * they look for the upKeepNeeded to return True.
     * These points should be True in order to return True
     * 1. Time Interval should have passed
     * 2. Lottery should have atleast one player and some eth.
     * 3. Our Subscription is funded with links.
     * 4. Lottery should be in an open state.
     */

    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        override
        returns (
            // maybe OVERRIDE might come here lets see if i get any errors later.
            bool upkeepNeeded,
            bytes memory /* Perform Data */
        )
    {
        bool isOpen = (LotteryState.OPEN == s_lotteryState);
        // (block.timestamp --> last block timestamp) > interval
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(bytes calldata /* Perform Data */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }
        // req the random number
        // if we get it do smthing with it
        // 2 transaction process
        s_lotteryState = LotteryState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //Max amount of gas we are willing to burn to get the random numbers
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedLotteryWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_lotteryState = LotteryState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        // wtf was this line about? -- guess--sending all the money to winner
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // we could do require(success) smthing smthing but we are not
        // instead we do
        if (!success) {
            revert Lottery__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* View/Pure Functions */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayers(uint256 index) public view returns (address) {
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

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getRequestConfimations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }
}
