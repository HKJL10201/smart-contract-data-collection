// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol"; //bring in the Vrf consumer base contract to help with generating random number

/*
 events are pieces of data executed in the block chain and stored in the block chain but are not accessible by the smart contract, can be thought off as the print line of block   chain
 events are more gas efficient than using a storage variable
 
  */
contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    uint256 public usdEntryFee;
    uint256 public randomness;
    address payable public recentWinner;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee; //associated with the link token needed to pay for our vrf contract request
    bytes32 public keyhash; //way to uniquely identify our chain link vrf

    //to create an event we first create an event type
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator, //  a vrf coordinator address param for vrf consumer constructor
        address _link, // link token address param for vrf consumer constructor
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        // we initialize the constructor of the our VRF consumer like this since we are inheriting it
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        // $50 minimum
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value > getEntranceFee(), "Not enough eth");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; //18 decimals
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        //insecure way of generating random numbers
        // uint256(
        //     keccak256(
        //         abi.encodePacked(
        //             nonce, // nonce is predictable (aka the trnsaction number)
        //             msg.sender, // msg.sender is predictable
        //             block.difficulty, //can be manipulated by miners
        //             block.timestamp //time stamp is predictable
        //         )
        //     )
        // ) % players.length;
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        //secure way of generating random
        bytes32 requestId = requestRandomness(keyhash, fee); // we call inbuilt function in our vrf consumer base contract
        // this is the first function call in the vrf consumer request reponse cycle.
        // in the first transaction we will request the data from the chain link oracle,
        // in a second call back transaction the chain link node will return the data into this contract with another function called fulfillRandomness.
        // once the chain link has created a random number , the chainlink will call a second transaction itself based off of what we define, the second transaction
        // must be called  fulfillRandomness

        // to emit an event
        emit RequestedRandomness(requestId);
        // event wil be emitted when this function is called
    }

    // this is call back function that will be called by chain link node,
    //  we make this internal so only the chainlink node can call the function
    // our override keyword means we are overriding the original function definition in the vrf consumer base contract
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet"
        );
        require(randomness > 0, "Random not found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance); // send and transfer are only available on type address payable

        //reset lottery
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
