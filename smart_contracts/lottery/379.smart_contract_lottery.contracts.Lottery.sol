// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public recentRandom;
    uint256 usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * 10**18;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN, "Lotery not open");
        //$50 min
        require(msg.value >= getEnteranceFee(), "Not enough ETH");
        players.push(payable(msg.sender));
    }

    function getEnteranceFee() public view returns (uint256) {
        //get eth/usd price and convert 50 usd to eth
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10;
        uint256 ethEnteranceFee = (usdEntryFee * 10**18) / adjustedPrice;
        return ethEnteranceFee;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Cannot start new lottery yet"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "Lottery does not exist yet"
        ); //check lottery is opne

        lottery_state = LOTTERY_STATE.CALCULATING_WINNER; //change state so other functions cant be called

        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough link to fulfill request"
        ); //check that contract can pay for rand num

        requestRandomness(keyhash, fee); //get rand num
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "Winner cannot be chosen yet"
        );
        require(
            _randomness > 0 && _randomness != recentRandom,
            "Random not found"
        ); //ensure random num was returned
        uint256 randomWinner = _randomness % players.length; //random num --> array index
        recentWinner = players[randomWinner]; //set winner
        recentWinner.transfer(address(this).balance); //pay
        //Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        recentRandom = _randomness; //to check next num against
    }
}
