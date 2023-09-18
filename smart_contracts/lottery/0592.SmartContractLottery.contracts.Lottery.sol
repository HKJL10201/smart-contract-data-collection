// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    uint256 public minFee = 50 * (10**18);
    bytes32 public keyhash;
    uint256 public fee;
    address public recentWinner;

    constructor(
        address _priceFeed,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyhash,
        uint256 _fee
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        lottery_state = LotteryState.Closed;
        keyhash = _keyhash;
        fee = _fee;
    }

    AggregatorV3Interface priceFeed;

    enum LotteryState {
        Open,
        Closed,
        Calculating_winner
    }

    event RequestedRandomness(bytes32 requestId);

    LotteryState public lottery_state;

    function enter() public payable {
        require(lottery_state == LotteryState.Open, "not open yet");
        require(getEntranceFee() <= msg.value);
        players.push(msg.sender);
    }

    function startLottery() public onlyOwner {
        require(lottery_state == LotteryState.Closed, "already open");
        lottery_state = LotteryState.Open;
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjPrice = uint256(price) * (10**10);
        uint256 ethFee = (minFee * (10**18)) / adjPrice;
        return ethFee;
    }

    function endLottery() public onlyOwner {
        require(lottery_state == LotteryState.Open);
        lottery_state = LotteryState.Calculating_winner;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        uint256 _index = _randomness % players.length;
        players[_index].transfer(address(this).balance);
        recentWinner = players[_index];
        lottery_state = LotteryState.Closed;
        players = new address payable[](0);
    }
}
