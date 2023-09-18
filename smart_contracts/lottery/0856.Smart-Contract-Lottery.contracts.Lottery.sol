// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

// import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract Lottery is Ownable, VRFConsumerBase {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public usdEntreeFee;
    uint256 public randomness;
    uint256 public fee;
    bytes32 public keyhash;

    AggregatorV3Interface internal ethUsdPriceFeed;
    enum Lottery_State {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    Lottery_State public lottery_state;

    constructor(
        address _priceFeed,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntreeFee = 5 * (10**16);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeed);
        lottery_state = Lottery_State.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        //50$ minimum

        require(lottery_state == Lottery_State.OPEN);

        require(msg.value >= getEntranceFee(), "Not Enough ETHER");

        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10;

        uint256 costToEnter = (usdEntreeFee * 10**18) / adjustedPrice;

        return costToEnter;
    }

    function getFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10;
        return adjustedPrice;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == Lottery_State.CLOSED,
            "Cant Start a Lottery yet"
        );

        lottery_state = Lottery_State.OPEN;
    }

    function endLottery() public onlyOwner {
        lottery_state = Lottery_State.CALCULATING_WINNER;
        bytes32 requestID = requestRandomness(keyhash, fee);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == Lottery_State.CALCULATING_WINNER,
            "You are not there yet"
        );

        require(randomness > 0, "random not found");
        randomness = _randomness;
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);

        // reset
        players = new address payable[](0);
        lottery_state = Lottery_State.CLOSED;
    }
}
