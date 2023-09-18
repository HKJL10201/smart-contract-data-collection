// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

//inherit both Ownable.sol and VRFConsumerBase.sol
contract Lottery is VRFConsumerBase, Ownable {
    mapping(address => uint256) public addressToAmountFunded;
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;
    AggregatorV3Interface public ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    //0
    //1
    //2

    //inherit from VRFConsumerBase's constructor
    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        // put in terms of Gwei
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        // could've also done lottery_state = 1
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH");
        addressToAmountFunded[msg.sender] += msg.value;
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        // $50, $3,000 / ETH, Solidity doesnt work w/ Decimals
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price * 10**10); // 18 decimals as price already has 8
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice; //usdEntry has 18 decimals, but so does price, multiply by another 18 to cancel out
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
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "No open lottery to close"
        );
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    //internal so that nobody else can call this except chainlink node
    //override - over rides original declaration of fulfill randomness cuz VRF Consumer has a function of fulfill randomness
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random not found");
        //use division to get an index number from 0 to players.length
        uint256 indexOfWinner = _randomness % players.length;
        // return the address of the winner at the given index number
        recentWinner = players[indexOfWinner];
        //transfer the funds of the address' balance to this winner
        recentWinner.transfer(address(this).balance);
        //Reset the lottery array and lottery state, save most recent random number
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
