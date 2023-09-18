/* Enter lottery (paying some amount)
 * pick a random winner (verifiably random)
 * Winner to be selected after X minutes -> completely automated
 * Chainlink Oracle -> Randomness, Automated execution (Chainlink keepers) */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
// import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

import "hardhat/console.sol";

error Raffle__NotEnoughtEthEntered();
error Raffle__IndexOutOfBounds();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpKeepNotNeeded(uint256 currentBalance, uint256 numberOfPlayers, uint256 raffleState);

/**
 * @title A Sample Contract
 * @author Muhammad Abdullah
 * @notice This contract is created for learning about smart contracts, this is a project of fcc course.
 * @dev This contract uses Chainlink vrf2 for getting verifiable random numbers from chainlink, and it uses chainlink keeper to automatically execute the contract.
 */
contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    // uint256 0 = OPEN, 1 = CALCULATING

    /* State variables */

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLimit;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 20;
    uint32 private immutable i_callBackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;

    address payable[] private s_players;

    /* Lottery variables */
    uint256 private immutable i_interval;
    RaffleState private s_raffleState;
    address private s_recentWinner;
    uint256 private s_lastTimeStamp;

    /* Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /* Functions */
    constructor(
        address vrfCoordinatorV2, //contract Address
        uint256 entranceFee,
        bytes32 gasLimit,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLimit = gasLimit;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callbackGasLimit;
        i_interval = interval;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    /**
     * @dev This function is called by chainlink keepers nodes,
     *      They look for 'upkeepNeeded' to return 'true'.
     * The following should be true in order to return true.
     * 1. Our time interval should have passed
     * 2. Lottery / Raffle should have atleast one player and have some ETH.
     * 3. Our subscription is funded with LINK.
     * 4. Lottery / Raffle should be in "open" state.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view override returns (bool upkeepNeeded, bytes memory performData) {
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        return (upkeepNeeded, performData);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLimit,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callBackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        uint256 randomWinnerIndex = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[randomWinnerIndex];
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        s_recentWinner = recentWinner;
        sendBalanceToWinner(recentWinner);
        emit WinnerPicked(recentWinner);
        s_raffleState = RaffleState.OPEN;
    }

    function sendBalanceToWinner(address payable recentWinner) internal {
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughtEthEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    /* view functions */
    function getEntraceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        address payable[] memory players = s_players;
        if (index < 0 || index >= players.length) {
            revert Raffle__IndexOutOfBounds();
        }
        return players[index];
    }

    function getLastPlayer() public view returns (address) {
        return getPlayer(s_players.length - 1);
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
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
}
