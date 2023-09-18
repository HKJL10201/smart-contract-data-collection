// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

// import the interface so that we can use the functions without having to define them
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

// the contract we will be using for trnsactions in the lotto
contract Lottery is VRFConsumerBase, Ownable {
    // create an array to track the address of the user entering the lotto
    address payable[] public players;
    // store the value of how much it will cost to enter the lotto price
    address payable public recentWinner;
    uint256 public usdEntryFee;
    uint256 public randomness;
    AggregatorV3Interface internal ethUsdPriceFeed;
    //
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    // 0
    // 1
    // 2
    // initalize the variables for the price of entering the lotto
    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        // values are done in brownie.config
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        // set the entry price for entering the lotto in USD then convert to WEI
        usdEntryFee = 50 * (10**18);
        // initialize ethUsd.. to the live pricefeed data from AggregatorV3
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    // function to enter the lottery with a $50 minimum add the player to the lotto
    function enter() public payable {
        // Checks to make sure that we are only able to enter the lottery if enum lottery_state is open
        require(lottery_state == LOTTERY_STATE.OPEN);
        // run the get entrance fee function or elese print not enough
        require(msg.value >= getEntranceFee(), "Not enough ETH!");
        players.push(msg.sender);
    }

    /**
    This is the network we will be using to collect the price feed data from 
    Network: Mainnet
    Aggregator: ETH/USD
    Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    // function to pull money from user address
    function getEntranceFee() public view returns (uint256) {
        // use only the price function to initialize ethUsd..
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        // conver price from int to uint so that we don't run into any errors
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals since it's WEI
        // $50, ... $2,000 / ETH...
        // $50/2,000
        // will have to do 50 * 100000 / 200
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    // block of code that runs in the beginning of the code
    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    // block of code to end the lotto
    function endLottery() public onlyOwner {
        // uint256(
        //     keccack256(
        //         abi.encodePakced(
        //             nonce, // nonce is predictable
        //             msg.sender, // msg.sender is predictable
        //             block.difficulty, // can be manipulated by the miners
        //             block.timestamp // timestamp is predictable
        //         )
        //     )
        // ) % players.length;
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random-not-found");

        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        // reset the lottery to start again
        players = new address payable[](0);
        // lottery complete
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
