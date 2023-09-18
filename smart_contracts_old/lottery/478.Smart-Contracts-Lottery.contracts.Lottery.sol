// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 internal usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    uint256 public fee;
    bytes32 public keyHash;
    event RequestRandomness(bytes32 requestId);
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;

    constructor(address _priceFeedAddress,
        address _vrfCoordinator,
        address _linkAddress,
        uint256 _fee,
        bytes32 _keyHash)
    public VRFConsumerBase(_vrfCoordinator, _linkAddress)  {
        usdEntryFee = 50 * (10 ** 18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyHash = _keyHash;
    }
    /**
     * user enters lottery by paying minimal entrance fee
     */
    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery is not started");
        require(msg.value >= getEntranceFee(), "Not enough ETH!");
        players.push(msg.sender);
    }
    /**
     * user can check out the entrance fee lottery
     */
    function getEntranceFee() public view returns (uint256) {
        (,int price,,,) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10 ** 10;
        //now has 18 decimals
        uint256 constToEnter = (usdEntryFee * 10 ** 18) / adjustedPrice;
        return constToEnter;
    }

    /**
     * only admin can start the lottery
     */
    function startLottery() public onlyOwner {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Cannot start a new lottery - when state is not closed!");
        lottery_state = LOTTERY_STATE.OPEN;
    }
    /**
     * only admin ends the lottery and a random user gets the pot
     */
    function endLottery() public onlyOwner {
        require(lottery_state == LOTTERY_STATE.OPEN, "Cannot end lottery - state need to be open!");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        //uint rand = uint(keccak256
        //    (abi.encodePacked(
        //            nonce, //nonce is predictable (aka, transaction number)
        //            msg.sender, // msg.sender is predictable
        //            block.difficulty, // can actually be manipulated by the miners
        //            block.timestamp //timestamp is predictable
        //        )
        //    )
        //) % players.length;
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RequestRandomness(requestId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 _randomness)
    internal override {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You are not there yet");
        require(_randomness > 0, "Random number not found");
        randomness = _randomness;
        uint256 index_of_winner = randomness % players.length;
        recentWinner = players[index_of_winner];
        recentWinner.transfer(address(this).balance);
        // reset the lottery
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
    }
}
