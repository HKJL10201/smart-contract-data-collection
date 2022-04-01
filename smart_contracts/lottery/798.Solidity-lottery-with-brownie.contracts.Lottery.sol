// SPDX-License-Identifier: Apache-2.0

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.6.0;

contract Lottery is VRFConsumerBase, Ownable {
    // variables
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
    // for VFR Coordinator:
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    // constructor
    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        // for vfr
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    // Functions

    function enterToLottery() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery is closed");
        require(msg.value >= getEntranceFee(), "Not enough ETH");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        // set entrance fee to $50
        // Eth/Usd conversion has 8 decimals so in order to make it 18 (wei standard) it's necessary to multiply the price.
        uint256 adjustedPrice = uint256(price) * (10**10); //18 decimals
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can´t start new lottery yet"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            // require an specific state of the lottery
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "you aren't there yet."
        );
        // Make sure the node have returned a random value
        require(_randomness > 0, "random-not-found");
        // Select the winner based on the pull of players using de modulo.
        uint256 indexOfWinner = _randomness % players.length;
        // to know who won last.
        recentWinner = players[indexOfWinner];
        // transfer all funds to the winner
        recentWinner.transfer(address(this).balance);
        //Reset the lottery players
        players = new address payable[](0);
        // change de lottery state
        lottery_state = LOTTERY_STATE.CLOSED;
        // to verify the rando number
        randomness = _randomness;
    }
}
