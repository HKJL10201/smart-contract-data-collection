// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {

    // Variables
    address payable[] public players;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal priceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    address payable public recentWinner;
    uint256 public randomness;
    event RequestRandomness(bytes32 requestId);
    //Constructor

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        lottery_state = LOTTERY_STATE.CLOSED;
        usdEntryFee = 50 * (10**18);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        fee = _fee;
        keyhash = _keyhash;
    }

    // Lottery entry function

    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "not Enough Eth!");
        players.push(msg.sender);
    }

    // Lottery entrancefee calculation (50$)

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    // Start Lottery only by owner

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "cant start a new lottery"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    // End Lottery only by owner, also request a random numbervfrom VRF
    function endLottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestRandomness(requestId);
    }

    // Get a Random Number from VRF

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {

        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "you aren't there yet!");
        require(_randomness > 0, "random not found!");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        // Reset
        players = new address payable[](0);
        randomness = _randomness;
        lottery_state = LOTTERY_STATE.CLOSED;

    }
}
