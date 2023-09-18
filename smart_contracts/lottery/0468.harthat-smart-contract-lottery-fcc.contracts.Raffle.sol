// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

// Errors
error Raffle__SendMoreToEnterRaffle();
error Raffle__TransferFialed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
);

/**@title A sample Raffle Contract
 * @author Gray Jiang
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */
contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    /* State variables */
    // Chainlink VRF Variables

    uint private immutable i_entranceFee; // 参加费用
    address payable[] private s_players; // 参与者数组
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; // 随机数生成接口
    bytes32 private immutable i_gasLane; // vrf唯一标识符（总的gas限制）
    uint64 private immutable i_subscriptionId; // 每个人用于募资的唯一id
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // 待确认区块
    uint32 private immutable i_callbackGasLimit; // 回调函数gas限制
    uint32 private constant NUM_WORDS = 1; // 随机数数量
    address payable private s_recentWinner; // 获胜者
    // uint256 private s_state; // raffle是否开启状态 pending,open,close,calculating
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /* Events */
    event RaffleEnter(address indexed player); // 参与事件
    event RequestRaffleWinner(uint256 indexed requestId); // 请求随机数事件
    event WinnerPicked(address indexed winner); // 选出获胜者事件

    /* Functions */
    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN; // s_raffleState = RaffleState(0);
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    /**
     * @dev 加入游戏的函数
     */
    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            // 首先检查支付额度是否小于入场费
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender)); // 将支付者加入到参与者数组
        emit RaffleEnter(msg.sender); // 触发参与事件
    }

    /**
     *
     * @dev the following should be true in order to return true;
     * 1. our time interval should have passed
     * 2.the lottery should have at least 1 player,and have enough ETH
     * 3.our description is funed with LINK
     * 4.the lottery should be in an 'poen' state
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out? cant
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //  VRF唯一标识符
            i_subscriptionId, // 每个人用于募资的唯一id
            REQUEST_CONFIRMATIONS, // 等待确认区块
            i_callbackGasLimit, //回调函数fulfillRandomWords的gas限制
            NUM_WORDS // 生成随机数数量
        );
        emit RequestRaffleWinner(requestId); // 触发请求随机数事件
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    function fulfillRandomWords(
        uint256,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        s_recentWinner = s_players[indexOfWinner];
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = s_recentWinner.call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert Raffle__TransferFialed();
        }
        emit WinnerPicked(s_recentWinner);
    }

    /** Getter Functions */

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    // 返回constant常量的函数为pure
    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
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

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
}
