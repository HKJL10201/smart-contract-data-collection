// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// Get the latest ETH/USD price from chainlink price feed
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner; 
    uint256 public randomness;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;

    //Lottery conditions

    //Not ending the lottery before the lottery starts
    //Not entering the lottery before the lottery has actually began

    //Store the various phases of lottery using enums

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

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link ) {
        //Convert to 18 decimals(wei)
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        //$50 dollars minimum entry fee
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        //Everything is calculated in wei
        //ethUsdPriceFeed.latestRoundData() returns 8 decimals, multiply by 10**10 to get 18 decimals(wei)
        uint256 adjustedPrice = uint256(price) * 10**10;
        //Convert usd to eth
        //multiply usdEntryFee times 18 decimals to make 36 decimal places
        //The additional 18 decimals will be cancelled after dividing by price to remain with 18
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        //cost to enter in wei
        return costToEnter;
    }

    //only called by admin
    //access control function provided by openzeppelin
    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Cant start a new lottery yet"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        //change state of our lottery
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        //Request a random number
        //returns a bytes32 called requestId
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    //Return a random number using our requestId
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        //Ensure state of lottery right now is at calculating winner
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        //ensure we get a response
        require(_randomness > 0, "random-not-found");
        //Example of picking index given randomness =22 and players=7 22 % 7 = 1
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        //transfer to winner all balance in the contract
        recentWinner.transfer(address(this).balance);
        //Reset to a brand new array
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }

    //Pick a random winner out of list of players
    //[1,2,3,4]
    //Do a modulo function
}
