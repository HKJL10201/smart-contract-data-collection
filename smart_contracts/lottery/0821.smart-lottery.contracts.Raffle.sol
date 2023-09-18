// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

error Raffle__NotEnoughETH();
error Raffle__TransferFailed();
error Raffle__NotOpen();

contract Raffle is VRFConsumerBaseV2, KeeperCompatible {
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    // Random number variables
    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint64 private immutable i_subId;

    // Upkeep variables
    uint256 private immutable i_interval;
    uint256 private s_lastTimestamp;

    uint256 private immutable i_entranceFee;
    address[] private s_players;
    address public owner;
    address payable private s_lastWinner;
    RaffleState private raffleState;

    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);
    event RaffleWinnerRequested(uint256 indexed requestId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Restricted access!");
        _;
    }

    constructor(
        address vrfCoordinatorAddress,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint64 subId,
        uint256 entranceFee,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorAddress) {
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_subId = subId;
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimestamp = block.timestamp;
        raffleState = RaffleState.OPEN;
        owner = msg.sender;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETH();
        }
        if (raffleState == RaffleState.CALCULATING) {
            revert Raffle__NotOpen();
        }
        s_players.push(msg.sender);
        emit RaffleEnter(msg.sender);
    }

    function checkUpkeep(
        bytes calldata /*chekcData*/
    )
        external
        view
        override
        returns (
            bool upkeepNeeeded,
            bytes memory /*performData*/
        )
    {
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        bool timePassed = (block.timestamp - s_lastTimestamp) > i_interval;
        upkeepNeeeded = (hasPlayers && hasBalance && timePassed);
    }

    function performUpkeep(
        bytes calldata /*performData*/
    ) external override {
        raffleState = RaffleState.CALCULATING;
        uint256 requestId = vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RaffleWinnerRequested(requestId);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        uint256 randomNumber = randomWords[0] % s_players.length;
        s_lastWinner = payable(s_players[randomNumber]);
        (bool success, ) = s_lastWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        s_lastTimestamp = block.timestamp;
        raffleState = RaffleState.OPEN;
        s_players = new address[](0);
        emit WinnerPicked(s_lastWinner);
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLastWinner() public view returns (address) {
        return s_lastWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return raffleState;
    }

    function getLatestTimestamp() public view returns (uint256) {
        return s_lastTimestamp;
    }
}
