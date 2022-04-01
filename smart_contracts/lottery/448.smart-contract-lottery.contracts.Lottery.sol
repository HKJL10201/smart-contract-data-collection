// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable {

    address payable[] public players;
    uint256 public usdEntranceFee;
    AggregatorV3Interface internal usdEthPriceFeed;
    enum LOTTERY_STATE {OPEN, CLOSED, CALCULATING_WINNER}
    LOTTERY_STATE public lottery_state;

    constructor(address _priceFeedAddress) public {
        usdEntranceFee = 50 * 10 ** 18;
        usdEthPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;

    }
    function enter() public payable {
        players.push(msg.sender);
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), 'Not enough ETH to enter!');
    }

    function getEntranceFee() public view returns (uint256){
        (, int price, , ,) = usdEthPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10 ** 10;
        uint256 priceToEnter = usdEntranceFee * 10 ** 18 / adjustedPrice;


        return priceToEnter;
    }

    function startLottery() public {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start yet"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

}