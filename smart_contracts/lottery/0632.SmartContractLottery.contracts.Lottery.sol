// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        open,
        closed,
        calculating_winner
    }
    // 0
    // 1
    // 2

    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeedAddress, // for the imported pricefeed
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.closed;
        fee = _fee; // for the imported consumerbase
        keyhash = _keyhash; // for the imported consumerbase
    }

    function enter() public payable {
        // 50$ min
        require(lottery_state == LOTTERY_STATE.open);
        require(msg.value >= getEntranceFee(), "Not enough ETH!");
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * (10**10); //18 decimals
        uint256 costToEnter = (usdEntryFee * (10**18)) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.closed,
            "Can't start a new lottery yet!"
        );

        lottery_state = LOTTERY_STATE.open;
    }

    function endLottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.calculating_winner;
        bytes32 requestID = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestID);
    }

    function fulfillRandomness(bytes32 _requestID, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.calculating_winner,
            "You aren't there yet"
        );
        require(_randomness > 0, "randomness-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        //reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.closed;
        randomness = _randomness;
    }
}
