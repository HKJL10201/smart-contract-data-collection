//SPDX-License-Identifier:MIT
//Blockchain is a deterministic system
//Getting atrue  Random number we are going to have  alook outside the blockchain
//cant use any api for obtaining any random number
///////////////////////////////////////////////////////////////////////
//ETH ->Pay some ETH/transaction gas to pay the smartcontract platform a littlebit of ETH for performing a transaction
//LINK->"For smartcontract that operate with an oracle" We pay using LINK gas/ oracle gas to pay the oracle for providing data or some type of external computation for a smart contract
//Events are pieces of data executed and stored  in the blockchain but not accesible by any smart contract 

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
//For the onlyOwner fxn
import "@openzeppelin/contracts/access/Ownable.sol";
//For random Number
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    // what fxns must we will use

    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    //This means that we have a new type called lottery state with 3 positions
    //0
    //1
    //2
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);


    //VRFConsumerBase paramters will be VRF consumeraddress,linktoken address
    //RandomContract wants a fee and keyHash

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        //Need to convert $50 to $50 in ETH
        usdEntryFee = 50 * (10 ** 18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        //AS LOTTERY_STATE are represented by NUMBERS we can easily state them aslo by
        //lottery_state=1(CLOSED)
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        //$50 min for any player to enter the lottery
       
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not Enough ETH!!");

        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        //getthePrice Fxn from AggregatorV3
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10 ** 10; //18 decimals
        //Setting the price $50, 1ETH=$2000
        //50/2000
        uint256 costToEnter = (usdEntryFee * 10 ** 18) / adjustedPrice;
        return costToEnter;
    }

    //Only admin can call
    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Cant Start the lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        //We get To know a random winner
        //Randomness
        //Blockchain is a deterministic system
        //getting a random number in a deterministic system is actually impossible
        //Having a exploitable randomness will doom you especially anything related to finance (LOTTERY)
        //ITS AN EASY SPOT FOR HACKERS
        /////////////////////////
        //1. This Vunrable method cant be used by any production used cases
        //insecure variables will do that they will use a globally varaible(ex: msg.sender /msg.value)and hash it

        // uint256(
        //     keccak256(
        //         abi.encodePacked(
        //             nonce,// nonce is predictable
        //             msg.sender,// msg.sender is predictable
        //             block.difficulty,// can be manipulated by the minners gives the miners to win the lottery
        //             block.timestamp//Timestamp is predictable
        //         )
        //     )
        // ) % players.length;
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);

    }
    //Internal because only the VRF coordinator can return the fxn 
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness ) internal override{
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You arent there Yet!");
        require(_randomness >0, "random-not-found");
        uint256 indexOfWinner=_randomness % players.length;
        recentWinner =players[indexOfWinner];

        //7 players 
        //random number:22
        // 22 % 7 = 1

        // the recentWinner will take all money added while entering the game 
        recentWinner.transfer(address(this).balance );

        //Reseting 
        players = new address payable [] (0);
        lottery_state=LOTTERY_STATE.CLOSED;
        randomness=_randomness;
    }
    

}
