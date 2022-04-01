// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    address payable public latestWinner;
    uint256 public randomness;

    // random number generator
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * 10**18;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyHash = _keyHash;
    }

    function enter() public payable {
        // set price as minimum USD $50
        uint256 minimumUSD = 50 * 10**18;
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH!");
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        // $50 USD * (decimals) / $2000 ETH
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Cannot start lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public {
        require(lottery_state == LOTTERY_STATE.OPEN, "Cannot end lottery yet!");
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;

        // actually don't need to decalre requestId, requestRandomness returns that var natively via:
        // function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId)
        // will decalre it here just for completeness though
        bytes32 requestId = requestRandomness(keyHash, fee);
        // now this function call follows request -> recieve pattern
        // the chainlink node will return the data to the contract via fulfillRandomness function
    }

    // override means override original declaration of the fulfillRandomness fucntion in VRFCoordinator Contract
    // make it internal so it can only be called by the VRF contract itself (which is inherited in Lottery contract)
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "Not there yet!!"
        );
        require(_randomness > 0, "random number not found");
        // players are just in an array, get player based off mod(_randomness, # players) index
        uint256 indexOfWinner = _randomness % players.length;
        latestWinner = players[indexOfWinner];
        latestWinner.transfer(address(this).balance);
        // Reset to new array of size zero
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
