// SPDX-License-Identifier: MIT

// Contract Objectives:
// Collect all Eth deposited in the Lottery
// Choose random Winner
// Reset Lottery after the Winner is selected
// Withdraw all ether to the winning lottery address

pragma solidity ^0.8.18;

/** IMPORTS */
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Lottery is VRFConsumerBaseV2 {
    /* Custom Errors */
    error ChooseWinner_TransferFailed();
    error Lottery__NotOwner();
    error Deposit_Failed();

    /*Type declarations */
    enum LotteryState {
        OPEN, // 0
        CALCULATING // 1
    }

    /* State Variables */
    address private immutable i_owner;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_entryFee;

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    address payable[] private s_players;
    mapping(address => uint256) private s_playersEntryDeposit;
    LotteryState private s_lotteryState;
    address private s_recentWinner;
    uint256 private s_numberOfLotteryRounds;
    uint256 private s_winningAmount;

    /** Events */
    event NumOfLotteryRounds(uint256 indexed rounds);
    event EnteredLottery(address indexed player);
    event WinnerSelected(address indexed player, uint256 indexed amountWon);
    event RequestedLotteryWinner(uint256 indexed requestId);

    /** Contructor */
    constructor(
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 entryFee,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_owner = msg.sender;
        i_entryFee = entryFee;
        s_lotteryState = LotteryState.OPEN;
        s_numberOfLotteryRounds = 0;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    // ENTER THE LOTTERY
    function enterLottery() public payable {
        require(s_lotteryState == LotteryState.OPEN, "Lottery is not open.");
        for (uint256 i = 0; i < s_players.length; i++) {
            require(
                msg.sender != s_players[i],
                "This address was already used. 1 entry per address."
            );
        }
        require(msg.sender != i_owner, "Contract owner can not enter lottery.");
        require(msg.value >= i_entryFee, "Not enough Eth deposited!");

        s_playersEntryDeposit[msg.sender] += msg.value;
        s_players.push(payable(msg.sender));

        emit EnteredLottery(msg.sender);
    }

    // CHOOSE WINNER
    function chooseWinner() external returns (uint256 requestId) {
        require(s_players.length > 0, "No players have entered the Lottery.");
        require(address(this).balance > 0, "No funds in lottery.");
        s_lotteryState = LotteryState.CALCULATING;

        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedLotteryWinner(requestId);
        return requestId;
    }

    // WITHRAW FUNDS TO WINNING ADDRESS
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(
            s_lotteryState == LotteryState.CALCULATING,
            "Lottery is still open."
        );
        require(s_players.length > 0, "No players have entered the Lottery.");

        // Grab winning address
        uint256 winningIndex = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[winningIndex];
        s_recentWinner = recentWinner;

        // Reset the Lottery
        s_lotteryState = LotteryState.OPEN;
        s_players = new address payable[](0);
        s_numberOfLotteryRounds++;

        // Update winning amount
        s_winningAmount = address(this).balance;

        // Emit events
        emit WinnerSelected(recentWinner, s_winningAmount);
        emit NumOfLotteryRounds(s_numberOfLotteryRounds);
        emit RequestedLotteryWinner(requestId);

        // Send winnings
        (bool success, ) = recentWinner.call{value: s_winningAmount}("");
        if (!success) {
            revert ChooseWinner_TransferFailed();
        }
    }

    /** GET FUNCTIONS */
    function getLotteryState() external view returns (LotteryState) {
        return s_lotteryState;
    }

    function getPlayersEntryDeposit(
        address fundingAddress
    ) external view returns (uint256) {
        return s_playersEntryDeposit[fundingAddress];
    }

    function getListOfPlayers()
        external
        view
        returns (address payable[] memory)
    {
        address payable[] memory listOfPlayers = new address payable[](
            s_players.length
        );

        for (uint256 i = 0; i < s_players.length; i++) {
            listOfPlayers[i] = s_players[i];
        }
        return (listOfPlayers);
    }
}
