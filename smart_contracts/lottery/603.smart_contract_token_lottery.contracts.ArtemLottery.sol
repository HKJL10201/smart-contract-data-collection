// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract ArtemLottery is VRFConsumerBase, Ownable, KeeperCompatibleInterface {
    bool constant AUTO_RESTART_KEEPER = true;
    bool constant START_ON_DEPLOY = true;
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    event LotteryEnded(
        bytes32 indexed requestId,
        address recentWinner,
        uint256 randomNumber
    );

    // 0
    // 1
    // 2
    /**
     * Use an interval in seconds and a timestamp to slow execution of Upkeep
     */
    uint256 public immutable lotteryDurationInSeconds;
    uint256 public lastTimeStamp;
    uint256 public lotteryCounter;
    bool public shouldRestart;

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash,
        uint256 _usdEntryFee,
        uint256 duration
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = _usdEntryFee;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
        lotteryDurationInSeconds = duration;
        lastTimeStamp = block.timestamp;
        lotteryCounter = 0;
        shouldRestart = START_ON_DEPLOY;
    }

    function enter() public payable {
        // $10 minimum
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH!");
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        // $50, $2,000 / ETH
        // 50/2,000
        // 50 * 100000 / 2000
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = ethUsdPriceFeed.latestRoundData();
        return price;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
        lastTimeStamp = block.timestamp;
    }

    function endLottery(bool _shouldRestart) public onlyOwner {
        endLotteryInternal(_shouldRestart);
    }

    function endLotteryInternal(bool _shouldRestart) internal {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = 0;
        if (players.length > 1) {
            requestId = requestRandomness(keyhash, fee);
        }
        emit RequestedRandomness(requestId);
        shouldRestart = _shouldRestart;
        if (players.length <= 1) {
            fulfillRandomness(requestId, 1);
        }
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random not found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        emit LotteryEnded(_requestId, recentWinner, randomness);
        recentWinner.transfer(address(this).balance);
        // Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        lastTimeStamp = block.timestamp;
        lotteryCounter = lotteryCounter + 1;
        randomness = _randomness;
        if (shouldRestart) {
            shouldRestart = false;
            startLottery();
        }
    }

    function checkUpkeep(bytes calldata checkData)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded =
            (block.timestamp - lastTimeStamp) > lotteryDurationInSeconds &&
            lottery_state == LOTTERY_STATE.OPEN &&
            players.length > 0;
    }

    function performUpkeep(bytes calldata performData) external override {
        endLotteryInternal(AUTO_RESTART_KEEPER);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlayersCount() public view returns (uint256) {
        return players.length;
    }
}
