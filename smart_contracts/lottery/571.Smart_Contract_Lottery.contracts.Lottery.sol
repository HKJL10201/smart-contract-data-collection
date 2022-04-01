//SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is
    VRFConsumerBase,
    Ownable //This is from openzeppelin i guess
{
    address payable[] public players;
    address payable public recentWinner; // payable because we are transferring some funds
    uint256 public usdEntryFee;
    uint256 public randomness;

    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    // OPEN,        - 0
    //CLOSED,       - 1
    //CALCULATING_WINNER - 2

    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);    //similiar ti an enum kinda

    /** VRFConsumerBase - constructor(adress _vrfcoordinator, address _link){
        vrfCoordinator = _vrfCoordinator        these two addresses changes based on the blockchain they are in
        LINK = LinkTokenInterface(_link)
    } */

    // keyhash - uniquely identifies the vrf node
    constructor (
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress); // 50 dollars to 50 dollars in ETH
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        // $50 minimum
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not Enough ETH!!");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; //18 decimals 8 + 10

        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice; //To match the units
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    // in VRFConsumerBase.sol  function requestRandomness returns (bytes32 requestId)

    function endLottery() public onlyOwner {
        // Randomness
        // Getting true randomness in a deterministic system is hard
        //Having exploitable randomness will be your doom

        // uint256(
        //     keccak256( // deterministic algorithm
        //         abi.encodePacked(
        //             nonce, // nonce is predictable (aka, transaction number)
        //             msg.sender, //msg.sender is predictable
        //             block.difficulty, // can actually be manipulated by the miners!
        //             block.timestamp // timestamp is predictable
        //         )
        //     )
        // ) % players.length;
        // hashing algorithm keccak256 is itselfdeterministic algorithm
        // so basically this way of randomness is bullshit

        // so we are going to chainlink VRF Provides verifiable randomness

        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee); // parameters present keyhash and fee


        emit RequestedRandomness(requestId);        // when called it will emit this into our transactions
        // this function follows request and receive mentallity
        //1st transaction we are gonna request data from chainlink oracle
        // 2nd transaction callback from the chainlink it will return the data to this contract into another function called fulfillRandomness
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        // we only want our chainlink node to call this functioin so it is internal
        //chainlink calls VRFCoordinator   VRFCoordinate call fulfillranomnes
        // only vrfcoordinator can call it
        // override bcoz fulfillRandomness is just emoty defined

        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            " you aren't there yet"
        );
        require(_randomness > 0, "random-not-found");

        // to pick a random player we are gonna do an modulo function

        uint256 indexOfWinner = _randomness % players.length;

        // 7 players; random = 22 => 22%7

        recentWinner = players[indexOfWinner];

        recentWinner.transfer(address(this).balance); // transferring all the money we have to the winner  owner -> winner

        //Reset

        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
