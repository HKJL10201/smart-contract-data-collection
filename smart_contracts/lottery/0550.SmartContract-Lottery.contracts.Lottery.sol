//SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable {
    address payable[] public players;
    uint public usdEnterFee;
    // priceFeed
    AggregatorV3Interface internal ethUsdPriceFeed;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    // OPEN -> 0
    // CLOSE -> 1
    // CALCULATING_WINNER -> 2

    LOTTERY_STATE public lottery_state;

    constructor(address _priceFeedAddress) public {
        usdEnterFee = 50 * (10 ** 18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function enter() public payable {
        // $50
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery is not open!");
        require(msg.value >= getEntranceFee(), "Not enought ETH!");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int answer, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(answer * 10 ** 10);
        // $50, $2,000 /ETH
        // 50 / 2000
        // 50 * 10000 / 2000
        uint256 costToEnter = (usdEnterFee * 10 ** 18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Lottery is already open!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public {}
}
