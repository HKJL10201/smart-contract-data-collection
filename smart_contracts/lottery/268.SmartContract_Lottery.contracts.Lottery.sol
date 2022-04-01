// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {

    address payable public recentWinner;
    address payable[] public players;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal usdToEthFeed;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;

    event RequestedRandomness(bytes32 requestId);

    uint256 public randomness;
    uint256 public fee;
    bytes32 public keyhash;

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public
    VRFConsumerBase(_vrfCoordinator, _link)
    {
        usdEntryFee = 50 * (10 ** 18);
        usdToEthFeed = AggregatorV3Interface(_priceFeedAddress);

        lottery_state = LOTTERY_STATE.CLOSED;

        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        // 50$ minimum
        require(msg.value >= getEntranceFeeInEth(), 'Not enough ETH!');
        require(lottery_state == LOTTERY_STATE.OPEN);
        players.push(payable(msg.sender));
    }

    function getEntranceFeeInEth() public view returns (uint256) {
        (, int256 conversionRate, , ,) = usdToEthFeed.latestRoundData();
        uint256 adjustedConversionRate = uint256(conversionRate * 10 ** 10);
        uint256 participationCost = (usdEntryFee * 10 ** 18) /
        adjustedConversionRate;
        return participationCost;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, 'Not there yet!');
        require(_randomness > 0, 'Random not found');
        uint256 winnerIndex = _randomness % players.length;
        recentWinner = players[winnerIndex];
        recentWinner.transfer(address(this).balance);
        // Reset lottery
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }

}
