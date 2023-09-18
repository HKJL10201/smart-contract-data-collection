// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//import "@chainlink/contracts/src/v0.7/interfaces/AggregatorProxyInterface.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players; // will going to use this to track all the players
    address payable public recentWinner;
    uint256 public usdEntryFee;
    uint256 public randomness;

    AggregatorV3Interface internal ethToUSDpriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    LOTTERY_STATE public lottery_state;

    uint256 public fee;
    bytes32 public keyhash;

    //event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18); //50 USD multiplied by 10 raised to the 18th
        ethToUSDpriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(
            msg.value >= getEntranceFee(),
            "You dont have enough ETH! , insufficient balance :("
        );
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethToUSDpriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; //18 decimals
        //$50, $2,000/ETH
        //50/2,000
        // 50* 100000 / 2000
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "You cant start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        lottery_state == LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee, 0);
        //emit RequestedRandomness(requestId); // this will write logs/event which will be helpfull in upgrading smart contracts
    }

    function fulfillRandomness(bytes32 _requesId, uint256 _randomness)
        internal
        override
    {
        //put some valid checks
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You are not there yet!!!"
        );
        require(_randomness > 0, "Random not found");

        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner]; // we have the winner!!
        recentWinner.transfer(address(this).balance); //transffering all the money to the random winner!!
        //Reset Lottery!!
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    } //this will override VRFConsumerBase fulfillRandomness function!
}
