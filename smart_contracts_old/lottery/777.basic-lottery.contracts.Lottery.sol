// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is Ownable, VRFConsumerBase {
    uint256 public usdEntranceFee;
    AggregatorV3Interface internal ethUSDPriceFeed;

    address payable[] public players;
    address payable public recentWinner;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;

    // for random number generation
    uint256 public fee;
    bytes32 public keyhash;
    uint256 public randomness;

    // emitted event for testing
    event RequestedRandomness(bytes32 requestId);
    event RandomnessReceived();

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntranceFee = 50 * (10**18);
        ethUSDPriceFeed = AggregatorV3Interface(_priceFeedAddress);

        // for random number generation
        fee = _fee;
        keyhash = _keyhash;

        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function enter() public payable {
        // require that lottery is currently open
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "Lottery is not currently open!"
        );

        // require $50 minimum entrance fee
        uint256 entrance_fee = getEntranceFee();
        require(
            msg.value >= entrance_fee,
            "Not enough ETH sent! Minimum is $50 worth."
        );
        // add address to list of players
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 price = getPrice();
        uint256 precision = 1 * (10**18);
        return (usdEntranceFee * precision) / price;
    }

    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = ethUSDPriceFeed.latestRoundData();

        // returning 1 ETH in USD -- 18 decimals
        return uint256(price) * (10**10);
    }

    function startLottery() public onlyOwner {
        // we can only start the lottery if it's currently closed
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Lottery is not closed! Cannot open lottery."
        );

        // set lottery_state
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        // we can only end the lottery if it's currently open
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "Lottery is not currently open! Cannot close lottery."
        );

        // set lottery state to CALCULATING_WINNER
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;

        // request the random number from the VRF Coordinator
        bytes32 requestId = requestRandomness(keyhash, fee); // request
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        // require that we are calculating a winner for this to be called
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "Lottery is not currently calculating a winner!"
        );

        // require that we've gotten a response from the VRF Coordinator
        require(_randomness > 0, "random-not-found");
        emit RandomnessReceived();

        // use random number to select random winner
        uint256 winner_index = _randomness % players.length;
        recentWinner = players[winner_index];

        // send winnings to the lottery winner
        recentWinner.transfer(address(this).balance);

        // reset the lottery
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
