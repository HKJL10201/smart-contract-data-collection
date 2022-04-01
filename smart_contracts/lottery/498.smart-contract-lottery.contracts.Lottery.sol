// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;
//Compiler using remote version: 'v0.8.8+commit.dddeac2f', solidity version: 0.8.8+commit.dddeac2f.Emscripten.clang

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Lottery {
    address payable[] public players;
    uint256 public usdEntryFee;
    AggregatorV3Interface public ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state = LOTTERY_STATE.OPEN;

    constructor(address _priceFeedAddress, uint256 _usdEntryFee) public {
        usdEntryFee = _usdEntryFee;
        //Initialize the lottery state?
        //check AggregatorV3Interface price feed and set the intial value
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function enter() public {
        //check if the lottery state is open
        require(lottery_state == LOTTERY_STATE.OPEN);
        //check if the amount is greater than/ equal to the enrance fee
        require(msg.value >= getEntranceFee(), "Not enouth ETH!");
        // add the player to the address array
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        // get the value from the public value variable
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**18;
        //$50/$2000 ETH
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public {
        // verify that the lottery state was closed, set it to open
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public {
        //close the lottery after calculating the winner
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
    }
}
