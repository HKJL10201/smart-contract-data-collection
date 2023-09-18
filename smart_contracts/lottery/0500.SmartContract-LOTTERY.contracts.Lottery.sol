// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
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
    /*
    ENUM is very simillar to struct but for each value in an enum represent 
    an integer starting from 0th index:
     -->>like first value in this cas is open which represents ->0 
     -->>like first value in this cas is open which represents ->1
     -->>like first value in this cas is open which represents ->2 */

    LOTTERY_STATE public lottery_state;
    uint256 public fee; //fee for chainlink node
    bytes32 public keyhash; //way to identify chain link node
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeed,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18); //conveting USD to Wei.
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeed);
        lottery_state = LOTTERY_STATE.CLOSED;
        //OR
        //lottery_state=1; since closed is at 1th index
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        //50$ minimum
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "Not Open Yet, Try after sometime"
        );
        require(msg.value >= getEntrenceFee(), "Not enough ETH!");
        players.push(msg.sender);
    }

    function getEntrenceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData(); //fetched price is in Wei
        uint256 adjustedPrice = uint256(price) * 10**10;
        uint256 costToEther = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEther;
    }

    function startLottery() public {
        require(lottery_state == LOTTERY_STATE.CLOSED, "cant start now");
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public {
        /*WEAK METHOD TO GET RANDOM NUMBER
        uint256(//converting everything to uint256
            keccak256(//it is hassing algorithm
                abi.encodePacked(
                    nonce,//priditiciable
                    msg.sender,//priditicable
                    block.difficulty,//can be manupaltated by miners
                    block.timestamp//priditicable
                )
            )
        ) % players.length;*/

        /*method 2: secure method to genrate random number is to use 
                    an api outside the block chain
                    API we will use here is chainlinkVRF do 
                    remember to re-map it in config file */
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);/*
        this emit will take bytes32 as requestid and return*/
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override{
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "Not there yet"
        );
        require(_randomness > 0, "random not found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        //transfering money to thr winner
        recentWinner.transfer(address(this).balance);
        //resertting the players to 0
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
