//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

error Lottery__NotEnoughETHEntered();
error Lottery__TransferFailed();
error Lottery__Closed();
error Lottery__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 lotteryState
);

contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
    //Type Declarations
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    //State Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    //Lottery Variables
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    address private s_recentWinner;
    uint256 private s_lastTimestamp;
    address payable[] private s_players;
    LotteryState private s_lotteryState;

    //Events
    event LotteryEnter(address indexed player);
    event RequestLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2Address, //Contract (indicator that we are going to need to deploy Mock)
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
        s_lotteryState = LotteryState.OPEN;
        s_lastTimestamp = block.timestamp;
        i_interval = interval;
    }

    //Enter function
    function enterLottery() public payable {
        //require msg.value >= i_entranceFee, if not then revert (with Custom Error)
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughETHEntered();
        }

        //Players can enter a lottery only if it is in OPEN state
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__Closed();
        }

        // if entrant has fullfiled the requirements he can go into an array of PLAYERS, one from that array will be a winner
        s_players.push(payable(msg.sender));

        // Emit an event when we update a dynamic array
        emit LotteryEnter(msg.sender);
    }

    /**
     * @dev This is the function that Chainlik Automation nodes will call.
     * They look for the 'upkeepNeeded to be true.
     * The following should be true in order to return true:
     * 1. Our time interval should have passed.
     * 2. The lottery should have at least 1 player and some amouht of ETH.
     * 3. Our subscription is funded with LINK.
     * 4. Lottery should be in an 'open' state.
     */

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /*performData*/)
    {
        bool isOpen = (LotteryState.OPEN == s_lotteryState);
        bool hasPlayers = (s_players.length > 0);
        bool hasETH = (address(this).balance > 0);
        bool timePassed = ((block.timestamp - s_lastTimestamp) > i_interval);
        upkeepNeeded = (isOpen && hasPlayers && hasETH && timePassed);
        //(block.timestamp - last.timestamp) > interval
        return (upkeepNeeded, "");
    }

    //Request random winner(via Chainlink VRF RNG)
    //This was a requestRandomWinner function! and now is performUpkeep
    function performUpkeep(bytes calldata /*performData*/) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }
        // Request the random number
        s_lotteryState = LotteryState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // Maximum gas price you are willing to pay for a request in wei.
            i_subscriptionId, // The subscription ID that this contract uses for funding requests.
            REQUEST_CONFIRMATIONS, // How many confirmations the Chainlink node should wait before responding.
            i_callbackGasLimit, // The limit for how much gas to use for the callback request to your contract’s fulfillRandomWords() function
            NUM_WORDS // How many random values to request.
        );

        emit RequestLotteryWinner(requestId);
    }

    //Winner function
    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        // Create a winner
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_lotteryState = LotteryState.OPEN;
        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;

        (bool success, ) = recentWinner.call{value: address(this).balance}("");

        if (!success) {
            revert Lottery__TransferFailed();
        }

        emit WinnerPicked(recentWinner);
    }

    //Get functions(View/Pure functions)
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 i) public view returns (address) {
        return s_players[i];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getNumWords() public pure returns (uint32) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimestamp() public view returns (uint256) {
        return s_lastTimestamp;
    }

    function getRequestConfirmations() public pure returns (uint16) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}
