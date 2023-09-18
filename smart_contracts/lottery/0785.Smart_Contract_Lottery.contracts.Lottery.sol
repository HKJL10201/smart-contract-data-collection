// SPDX-License-Identifier: MIT
// ------------------------------ Documentation ------------------------------- //
// Module:  Lottery.sol
// Decentralized lottery app. Look at readme file.
//
//
// Modification History
// 04-12-2022 SRK - Project Created.

// ------------------------------ Contract Setup ------------------------------ //

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    // ------------------------------ Variables ------------------------------ //
    // Create an array which will hold the address of the people who enter the
    // lottery.
    address payable[] public players;
    address payable public recentWinner;
    // This variable holds the entry fee for the lottery.
    uint256 public usdEntryFee;
    // This variable will store the address for the Chainlink ETH to USD price feed.
    AggregatorV3Interface internal ethUsdPriceFeed;
    // We will use this to identify the lottery state, open, closed and
    // calculating the winner.
    // Enums save the items inside it by number so 0=OPEN, 1=CLOSED,
    // 2=CALCULATING_WINNER.
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    // Initialze the lottery state variable which is of the type we just defined.
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    uint256 public randomness;

    // Create an event for us to pull later.
    event RequestedRandomness(bytes32 requestID);

    // Since this contract has inherityed functions from the VRFConsumerBase
    // contract we can specify addresses and parameters that are required in
    // that contract by adding them to our constructor.
    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        // $50 entry fee, but we have to convert it to Wei. So lets add some
        // decimals.
        usdEntryFee = 50 * (10**18);
        // We're going to need to pass the address for the Chainlink ETH to USD
        // Price Feed to this variable.
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        // When the contract is deployed this will set the state to CLOSED.
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    // ------------------------------ Functions ------------------------------ //
    // The enter() function will al low players to join the lottery.
    function enter() public payable {
        // We must require that people enter the lottery only when it's OPEN.
        require(lottery_state == LOTTERY_STATE.OPEN);
        // Make sure that everyone enters the lottery with atleast $50 worth of Eth.
        require(
            msg.value >= getEntranceFee(),
            "You need to use atleast $50 worth of ethereum."
        );
        //When this function is called, the address of the player entering the
        // lottery will be pushed to the players array.
        players.push(msg.sender);
    }

    // This function will get the current ETH/USD price conversion so we can ensure
    // that the player pays the fee of $50 with of Ethereum.
    function getEntranceFee() public view returns (uint256) {
        // The latestRoundData function from the AggregatorV3Interface return a
        // bunch of different items, we only care about getting the price.
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        // The latestRoundData documentation also states it will return the number
        // with 8 decimal places (remember solidy doesnt use decimals) we need it
        // to be 18 decimal places so we're gonna do some mathy math.
        uint256 adjustedPrice = uint256(price * 10**10);
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    // This function will set the lottery to an OPEN state so people can join it.
    function startLottery() public onlyOwner {
        // Only call this function if the lottery is currently closed.
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet."
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    // This function will allow the admin to close the lottery so it will select
    // the winner. The contract will randomly select a winner. We have to get
    // a random number from an outside source. You cannot generate a random number in
    // a deterministic system, and since it's 'random' each node would generate a
    //  different number we wouldn't be able to verify the block.
    function endLottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestID = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestID);
    }

    // fulFillRandomness is a function build into the VRFConsumer contract which
    // we've inherited. The override keyword allows us to use our code in that
    // contract instead of the code in that contract (which is empty). We are going
    // to pass it the reuestId and random number and have it determine
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        // require that the lottery is calculating a winnner.
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet."
        );
        // Require that the random number is not 0.
        require(_randomness > 0, "Random-Not-Found");
        // Here is how we select the winner. We use the modulo function to get a
        // remainder based off the random number and the number of players and set
        // this to the variable indexOfWinner.
        uint256 indexOfWinner = _randomness % players.length;
        // Next we go through the players list and use the indexofWinner to select
        // the winner in the list. This variable was initialized at the top of
        // the code.
        recentWinner = players[indexOfWinner];
        // Transfer the entire balance store in this contract to the address of
        // the winner.
        recentWinner.transfer(address(this).balance);
        // Finally lets reset the lottery so we can play again. We'll wipe out
        // the current list of players. Then we close the lottery so it can't
        // accept new players until the admin opens it.
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
