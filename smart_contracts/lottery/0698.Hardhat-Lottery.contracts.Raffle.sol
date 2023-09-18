//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//引入chainlinkvrf消费者合约
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

import "hardhat/console.sol";

//定义一个error去revert相比于你去require更节省gas
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
error Raffle__SendMoreToEnterRaffle();
error Raffle__RaffleNotOpen();

//给中奖者赚钱的error
error Raffle__TransferFailed();

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    //在测试代码中枚举会被自动转换成big int类型，open代表的就是0，calculating代表1.
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    //定义一个事件方便记录,这种方法的Gas效率比将内容保存在Storage里要高
    //定义在event里的数据，以特殊数据保存在evm日志里，智能合约无法访问，但是前端可以
    //添加indexed方便前端查找，在一些变量变化后记录事件进去，前端可以做出有效反馈
    //参与者记录
    event RaffleEnter(address indexed player);

    //请求随机数记录
    event RequestedRaffleWinner(uint256 indexed requestId);
    //胜者记录
    event WinnerPicked(address indexed recentWinner);

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    //keyHash
    bytes32 private immutable i_gasLane;

    //订阅id，再chainlink网站上创建订阅后，然后fund进去一定数量link可以得到
    uint64 private immutable i_subscriptionId;

    //在fulfillRandomWords函数中你愿意花费多少gas,防止gas skyrocket了你还去申请随机数。
    uint32 private immutable i_callbackGasLimit;

    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    uint32 private constant NUM_WORDS = 1;

    // ----------Lottery Variables-------------
    uint256 private immutable i_interval;
    //定义进入彩票合约的门槛不可变
    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;

    //保存每个参与者，数组一定是payable的
    address payable[] private s_players;
    RaffleState private s_raffleState;

    // ----------Lottery Variables-------------

    //构造函数，初始化不可变变量

    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_entranceFee = entranceFee;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
    }

    //进入合约，判断购买金额是否达到要求，符合即代表参与彩票合约，将此付款地址记录，并emit event
    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));

        //Emit an event when we update a dynamic array or mapping
        //Name events with the function name reversed
        emit RaffleEnter(msg.sender);
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
    /**
     * @dev 这是chainlink keeper节点调用的函数，他们寻找“upkeepNeeded”以返回true
     * 如果upkeepNeeded为true,这意味着是时候获取一个新的随机数了
     * 返回true的条件为:
     * 1.我们的时间间隔已经过去了
     * 2.彩票合约至少有一位参与者,并且有一些ETH在合约账户上
     * 3.我们的订阅由 LINK 资助
     * 4.彩票应处于“打开”状态
     */

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    //从参与者中选出获胜者，利用chainlink vrf
    //在调用checkUpkeep得到true后，此函数会且只会被chainlink keepers network 自动调用
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //keyHash,
            i_subscriptionId, //s_subscriptionId,
            REQUEST_CONFIRMATIONS, //requestConfirmations,
            i_callbackGasLimit, //callbackGasLimit,
            NUM_WORDS //numWords
        );
        // Quiz... is this redundant?
        //发送随机数事件
        emit RequestedRaffleWinner(requestId);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    //我们调用chainlink随机数后，chainlink vrf节点生成随机数后会传递到这个方法
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        // s_players size 10
        // randomNumber 202
        // 202 % 10 ? what's doesn't divide evenly into 202?
        // 20 * 10 = 200
        // 2
        // 202 % 10 = 2
        //获得胜利者在玩家数组中的索引
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        //获得胜利者的地址(可验证的随机获胜者)
        address payable recentWinner = s_players[indexOfWinner];
        //把获胜者放入storage中
        s_recentWinner = recentWinner;
        //重置参与获奖者的数组
        s_players = new address payable[](0);
        //上轮抽奖结束，此时可以吧抽奖状态设置为open开始下一轮
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        //把余额里的钱汇给获胜者
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(success, "Transfer failed");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        //发送一个事件记录获胜者，后面前端方便用来查询历届获奖名单
        emit WinnerPicked(recentWinner);
    }

    /** Getter Functions */

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

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
