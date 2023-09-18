// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is Ownable, VRFConsumerBase {
    address payable[] public players;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee; // LINK token needed to pay for the random number requst
    bytes32 public keyhash; // a unique way to identify Chainlink VRF node

    address payable public recentWinner;
    uint256 public randomness;

    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee, //it may change from blockchain to blockchain
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18); //$50
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED; // or lottery_state = 1; but less readable
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH!"); // set minimum
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData(); // price has 8 decimal
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice; // 10**18 to turn ETH into Wei
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        /*   
        ## don't use this pseudorandom number method for production ##
        uint256( //convert the hash result into a uint256 number
        keccack256( // hashing, which itself is not random, a bunch of globally available variables
            abi.encodePacked(
                nonce, // nonce is preditable (aka, transaction number)
                msg.sender, // msg.sender is predictable
                block.difficulty, // can actually be manipulated by the miners!
                block.timestamp // timestamp is predictable
            )
        )
        ) % players.length; // generate a number from 0 to length-1 as index to pick the winning player  */

        lottery_state = LOTTERY_STATE.CALCULATING_WINNER; // so no one can startLottery

        // first step of getting the random number
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    // second step of getting the random number
    // 'internal': only VRFCoordinator can call this
    // 'override': VRFConsumerBase.sol fulfillRandomness() has no parameters and meant to be overriden
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        // Reset
        players = new address payable[](0); // array of size zero
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness; // just keep a record of the recent random number
    }
}
