// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
// Enter the lottery(playing some amount)
// Pick a random number(verifyable random number)
// Winner to selected everu=y X minutes - Or X years fully automated
// Chain link oracle -> Randomness Automated Exceaution -> Chainlink Keepers

error Lottery__NotEnoughEthEntered();
error Lottery__TransferFailed();
error Lottery__NotOpen();
error Lottery__UpKeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /** Type declarations */
    enum LotteryState {
        OPEN,
        CALCULATING
    }
    /* State Variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLaneHash;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callBackGasLimit;
    uint32 private constant NUM_OF_WORDS = 1;

    /**Lottery variables*/
    address private s_recentWinner;
    LotteryState private s_lotteryState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    event LotteryEnter(address indexed players);
    event ReqestedLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCordinatorv2,
        uint256 entranceFee,
        bytes32 gasLaneHash,
        uint64 subscriptionId,
        uint32 callBackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCordinatorv2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCordinatorv2);
        i_gasLaneHash = gasLaneHash;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callBackGasLimit;
        s_lotteryState = LotteryState.OPEN;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterLottery() public payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughEthEntered();
        }
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit LotteryEnter(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = (LotteryState.OPEN == s_lotteryState);
        bool timepassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timepassed && hasPlayers && hasBalance);
        return (upkeepNeeded, "0x0");
    }

    // VRF Version 2- In VRF version 1 you would be funding your contract with link in VRF version 2 you would be funding
    // your subscription which is basically a account that allows you to fund and maintain balance for multiple
    // consumer contract.
    function performUpkeep(bytes calldata /* performData */) external override {
        /** Request the random number
         * Once we get it, We'll do something with it.
         * Chainlink VRF is two transation process
         * If it is one transaction then people can brute force tries simulating calling this trasaction.
         * s_subscriptionId - Is the subscription that we need to funding our requests.
         */
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }

        s_lotteryState = LotteryState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLaneHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callBackGasLimit,
            NUM_OF_WORDS
        );
        emit ReqestedLotteryWinner(requestId);
    }

    /**Chainlink keepers will call this function. */
    function fulfillRandomWords(
        uint256,
        /*requestId */ uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_players = new address payable[](0);
        (bool success, ) = recentWinner.call{value: address(this).balance}("");

        if (!success) {
            revert Lottery__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /** View/Pure functions - Note - External functions are cheaper then the public functions
     * as solidity knows that our contract cannot call this function.
     */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getNumberofPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_OF_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getvrfCoordinatoraddress() public view returns (VRFCoordinatorV2Interface) {
        return i_vrfCoordinator;
    }

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }
}
