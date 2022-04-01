// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// Inheritance (from Ownable)
contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    address payable[] public winners;
    uint256 public rounds;
    uint256 usdEntryFee = 50;
    AggregatorV3Interface internal busdToEthPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    uint256 randomness;
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeed,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        busdToEthPriceFeed = AggregatorV3Interface(_priceFeed);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        // Lottery still open
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "Sorry, the lottery is closed. Come back later!"
        );
        // $50 minimum
        require(
            msg.value >= getEntranceFee(),
            "Insufficent entry fee: $50 or more"
        ); // entrance fee already in wei (chainlink return with 18 decimals)
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = busdToEthPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price); // ETH has 18 decimals (already in wei)
        // convert $50 to ETH (wei)
        uint256 costToEnter = usdEntryFee * adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "The lottery is already open. Can't start a new one yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "The lottery is already closed."
        );
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        // pick winner
        // request
        bytes32 requestId = requestRandomness(keyhash, fee);
        // receive and pay winner Coordinator implemented by calling fulfillRandomness()
        // emit event
        emit RequestedRandomness(requestId);
    }

    // function for a response call from the VRF Coordinator
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
        recentWinner.transfer(address(this).balance); // transfer lottery balance to winner
        // reset the lottery
        players = new address payable[](0); // players to brand-new array
        lottery_state = LOTTERY_STATE.CLOSED; // close the lottery
        randomness = _randomness;
        winners.push(recentWinner);
        rounds++;
    }
}
