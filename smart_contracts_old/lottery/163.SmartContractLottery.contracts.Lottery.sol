// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

//All uint256 values will have 18 decimals

contract Lottery is Ownable, VRFConsumerBase {
    address payable[] public players;
    uint256 public USDEntryFee;
    AggregatorV3Interface internal ETHUSDPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint256 public vrfFee;
    bytes32 public vrfKeyHash;
    address payable public lastWinner;
    uint256 public latestRandomNumber;
    event RequestRandomness(bytes32 requestId);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        USDEntryFee = 25 * (10**18);
        ETHUSDPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        vrfFee = _fee;
        vrfKeyHash = _keyHash;
    }

    function getEntranceFee() public returns (uint256) {
        (, int256 price, , , ) = ETHUSDPriceFeed.latestRoundData();
        //price has 8 decimals by default
        uint256 ETHUSDPrice = uint256(price) * 10**10;
        //multiply USDEntryFee by 10**18 to preserve 18 decimals in answer
        uint256 entryFee = (USDEntryFee * 10**18) / ETHUSDPrice;
        return entryFee;
    }

    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery is closed");
        require(msg.value >= getEntranceFee(), "Entry fee is $25");
        players.push(payable(msg.sender));
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Lottery is already open"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(vrfKeyHash, vrfFee);
        emit RequestRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "Lottery not in correct state"
        );
        require(_randomness > 0, "Cannot confirm validity of random value");
        uint256 winningIndex = _randomness % players.length;
        lastWinner = players[winningIndex];
        lastWinner.transfer(address(this).balance);
        //Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        latestRandomNumber = _randomness;
    }
}
