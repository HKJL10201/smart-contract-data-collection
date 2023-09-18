// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

error Lottery__NotEnoughEthSent();
error Lottery__TransferFailed();
error Lottery__LotteryNotOpen();
error Lottery__NoUpdateNeeded();

// in the docs, the "VRFv2Consumer" is our Contract. So what that contract is doing is what our contract should be doing plus our own added functionalities ;)

/**
 * @title A sample Lottery contract
 * @author Edison Mgbeokwere
 * @notice This contract is for creating an untamperable loterry application
 * @dev This contract implements Chainlink VRF v2 and ChainLink keepers
 */

contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
    //Enter the lottery (pay some amount)
    //Pick a random winner (verifyably random)
    //Winner to be selected every X minutes -> completely automated
    //Chainlink oracle -> Randomness (chainlink VRF), Automated execution (chainlink keepers)

    /* Type Declarations */
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    /*State variables */
    VRFCoordinatorV2Interface private immutable i_coordinator; //big guy coordinating the request
    uint256 private immutable i_entranceFee;
    address payable[] private s_players; // because one of these address will receive money
    bytes32 private immutable i_keyhash; // this is to set a max gas price so incase a request for a random number is too high, that request fails. gotten from the VRF docs
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit; // gotten from the VRF docs
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    /*Lottery Variables */
    address private s_recentWinner;
    LotteryState private s_lotteryState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /*Events */
    event LotteryEnter(address indexed player); // "indexed" so that it's easily searchable in the logs
    event RequestedLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 _entranceFee,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_coordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_entranceFee = _entranceFee;
        i_keyhash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    function enterLottery() public payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughEthSent();
        }
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__LotteryNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit LotteryEnter(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink keeper node calls
     * they look for the "upkeepNeeded" to return true
     * The following should be true for upkeepNeeded to return true:
     * 1. Our time interval should have passed
     * 2. The lottery should have at least 1 player and some ETH
     * 3. Our subscription is funded with LINK
     * 4. The lottery should be in an "open" state
     */
    function checkUpkeep(
        // this function is required by the chainlink Keepers nodes to check if an update is needed
        bytes memory /*checkData */ // "public" makes this funtion accessible to us in the contract so we can read from it in "performUpkeep"
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /*performData*/
        )
    {
        bool isOpen = (s_lotteryState == LotteryState.OPEN);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 2);
        bool hasBalance = (address(this).balance > 0);

        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(
        /**
         * this was used to replace the "requestRandomWords()" function required by chainlink VRF nodes so that the chainlink Keepers nodes can call it automatically when an update is needed
         */
        bytes calldata /*performData */
    ) external override {
        // (bool updateNeeded, ) = checkUpkeep("");
        // if (!updateNeeded) {
        //     revert Lottery__NoUpdateNeeded();
        // }
        s_lotteryState = LotteryState.CALCULATING;
        // Request the random Winner
        // Once we get it, do something with it
        uint256 requestId = i_coordinator.requestRandomWords(
            i_keyhash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS // number of random values we requested for
        );
        // the first event will come when the "requestRandomWords" function is fired in our Mock VRF Coordinator
        emit RequestedLotteryWinner(requestId); // this will actually be the second event emitted
    }

    function fulfillRandomWords(
        // this function is required and automatically called  by the chainlink VRF coordinator nodes to perform a task when valid request id is given and  a random number is generated
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length; // the vrf nodes send a random value using "randomWords" that can now be used in the contract as we please
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_lotteryState = LotteryState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /*View / Pure functions */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
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

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }
}
