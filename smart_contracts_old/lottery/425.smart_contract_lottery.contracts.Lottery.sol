// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

//Lottery contract inherits Open Zeppelins Ownable contract and the VRFConsumerBase
contract Lottery is VRFConsumerBase, Ownable {
    //Make an array to keep track of all the players
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

    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        // $50 minimum
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not Enough Eth");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        // Get the latest price of Ethereum
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        //convert int price to a unit256 datatype
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals

        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    // Get a random winner at the end of the lottery (Request Random)
    function endLottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
    }

    // (Return Random) Use override modifier to overpower the inherited function fulfillRandomness
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );

        require(_randomness > 0, "random-not-found");

        //pick a random winner out of the list of payable players
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];

        // Transfer the winner the balance of the contract
        recentWinner.transfer(address(this).balance);

        // Reset the lottery
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.OPEN;
        // Keep track of the most recent random number
        randomness = _randomness;
    }
}
