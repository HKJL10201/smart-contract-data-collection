// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

import "./Libraries/PriceConvertor.sol";

contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
    // using library for converting eth amount into usd

    //type decelerations
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    // state variables
    uint256 public lotteryBalance;
    uint256 public entranceFee; // required amount in usd to join the lottery eg: 20$
    AggregatorV3Interface public priceFeed; // price feed contract address ETH/USD
    uint256 public timeInterval; // required time in seconds to pass to result the lottery
    uint256 public endTime;
    uint16 public platformFee; // platform fee in percentage eg: 25 = 2.5%
    address public owner; // owner of the platform
    address[] public players;
    address public recentWinner;
    LotteryState public lotteryState;

    // required variables for chainlink vrf
    VRFCoordinatorV2Interface public immutable vrfCoordinatorV2;
    bytes32 private immutable gasLane;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint16 private constant NUM_WORDS = 1;
    uint32 private immutable callbackGasLimit;
    uint64 public immutable subscriptionId;

    // mappings

    // **** address => balance amount
    mapping(address => uint256) public balance; // for get track of winners and admin balance

    // events
    event LotteryJoin(address indexed player);
    event RequestedLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    //modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    // initialize the contract
    constructor(
        uint256 _entranceFee,
        uint16 _platformFee,
        address _priceFeed,
        uint256 _timeInterval,
        address _vrfCoordinatorV2,
        uint64 _subscriptionId,
        bytes32 _gasLane,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        owner = msg.sender;
        lotteryState = LotteryState.OPEN;
        endTime = block.timestamp + _timeInterval;
        entranceFee = _entranceFee * 1e18;
        platformFee = _platformFee;
        priceFeed = AggregatorV3Interface(_priceFeed);
        timeInterval = _timeInterval;
        vrfCoordinatorV2 = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        subscriptionId = _subscriptionId;
        gasLane = _gasLane;
        callbackGasLimit = _callbackGasLimit;
    }

    // functions

    function joinLottery() external payable {
        require(lotteryState == LotteryState.OPEN, "Lottery is not open");

        // check the input amount in
        require(
            PriceConvertor.getConvertedPrice(msg.value, priceFeed) >=
                entranceFee,
            "insufficient funds"
        );

        lotteryBalance += msg.value;
        players.push(msg.sender);

        emit LotteryJoin(msg.sender);
    }

    /**
     * @dev the function which chainlink keeper nodes call
     * @return upkeepNeeded expected to be true
     */
    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /*performData*/)
    {
        bool isOpen = (lotteryState == LotteryState.OPEN);
        bool timePassed = block.timestamp > endTime;
        bool hasPlayers = (players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    /**
     * @dev then function which runs automatically if upkeep needed
     * @notice it sends request for random numbers
     */
    function performUpkeep(bytes calldata /*performData*/) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "upkeep not needed");

        lotteryState = LotteryState.CALCULATING;

        // request random words
        uint256 requestId = vrfCoordinatorV2.requestRandomWords(
            gasLane,
            subscriptionId,
            REQUEST_CONFIRMATION,
            callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedLotteryWinner(requestId);
    }

    /**
     * @dev the function which runs after getting the random number
     * @notice picks the winner and update the balances
     */
    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % players.length;
        address winner = players[indexOfWinner];
        recentWinner = winner;

        //reset the lottery
        players = new address[](0); // problem
        lotteryState = LotteryState.OPEN;
        endTime = block.timestamp + timeInterval;

        uint256 ownerFee = (lotteryBalance * platformFee) / 1000;
        uint256 winnedAmount = lotteryBalance - ownerFee;
        lotteryBalance = 0; //problem

        balance[owner] += ownerFee; //problem
        balance[winner] += winnedAmount; //problem

        emit WinnerPicked(winner);
    }

    function withdraw() external {
        uint256 amountToWithdraw = balance[msg.sender];
        require(amountToWithdraw > 0, "No balance");

        balance[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}(
            ""
        );
        require(success, "Failed to withdraw");
    }

    /**
     * @notice update the entrance fee in usd with 18 decimals
     */
    function updateEntranceFee(uint256 _entranceFee) external onlyOwner {
        entranceFee = _entranceFee * 1e18;
    }

    /**
     * @notice update the platform fee in percentage
     */
    function updatePlatformFee(uint16 _platformFee) external onlyOwner {
        platformFee = _platformFee;
    }

    /**
     * @notice update the time interval in seconds
     */
    function updateTimeInterval(uint256 _timeInterval) external onlyOwner {
        timeInterval = _timeInterval;
    }

    function getNumberOfPlayers() external view returns (uint256) {
        return players.length;
    }

    /**
     * @notice function for calculating entrance fee by ether
     * eg: if price is 1000$ and entrance fee is 100$ amount in eth is 0.1
     */
    function getEntranceFeePerETH() external view returns (uint256) {
        uint256 price = PriceConvertor.getPrice(priceFeed);
        return 1e18 / (price / entranceFee);
    }
}
