// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.0;

// Import the price feed.
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

// Import random number to choose the winner.
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

// More at https://docs.openzeppelin.com/contracts/4.x/
// Check at access/ownable
// To remove the error underlined add to the settings.json
import "@openzeppelin/contracts/access/Ownable.sol";

// Lottery is ownable - why?
contract Lottery is VRFConsumerBase, Ownable {
    //
    address payable[] public players;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    address payable public recentWinner;
    uint256 public randomness;

    // Create enum (more at https://docs.soliditylang.org/en/v0.8.11/types.html#enums)
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;

    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    // Constructor.
    constructor(
        address _priceFeedAdress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAdress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    // User enters the lottery.
    // Users will have to pay, so we need the payable modifier.
    function enter() public payable {
        // Lets set the minimum ammount of 5$ to enter the lottery.
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH!");

        players.push(payable(msg.sender));
    }

    // Entrance fee (calculated to USD).
    function getEntranceFee() public view returns (uint256) {
        //
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        // Adjust the price to unsigned integer 256 bits and make 18 decimals.
        uint256 adjustedprice = uint256(price) * (10**10);
        // Cost to enter.
        uint256 costToEnter = (usdEntryFee * (10**18)) / adjustedprice;
        return costToEnter;
    }

    // Start the lottery.
    function startLottery() public onlyOwner {
        // Only start the lottery if it's closed.
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't sart a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    // End the Lottery (request the random number).
    function endLottery() public onlyOwner {
        // Get a random winner. How to get a random number?
        // Pseudo-random (DO NOT USE)
        /*
        uint256(
            keccak256(
                abi.encodePack(
                    nonce, // predictable (aka, transaction number)
                    msg.sender, // predictable
                    block.difficulty, // Can be manipulated by miners.
                    block.timestamp // predictable
                )
            )
        ) % players.length;
        */

        // Get random number from chainlink! Import!

        // Change the lottery state (block all other operations).
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        // Request the random number. From the VRFConsumerBase contract.
        bytes32 requestId = requestRandomness(keyhash, fee);
        // Emit an event!
        emit RequestedRandomness(requestId);
    }

    // Get the random number.
    // It's internal because ony the VRFConsumerBase can call this function.
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "Wait...");
        require(_randomness > 0, "random-not-found");

        // Choose the index of the winner.
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];

        // Pay the winner.
        recentWinner.transfer(address(this).balance);

        // Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
