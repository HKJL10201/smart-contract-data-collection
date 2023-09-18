//SPDX-License-Identifier:MIT
pragma solidity ^0.6.0;


import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//import "@chainlink/contracts/src/v0.6/interfaces/VRFCoordinatorInterface.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
//is Ownable --to do more research on this...

contract Lottery is VRFConsumerBase, Ownable{
    address payable[] public players;
    uint256 minimumUSDamt = 50 * (10**18);
    AggregatorV3Interface priceFeed;
    uint256 fee;
    address payable admin;
    bytes32 keyhash;
    address payable public recentWinner;
    uint256 public randomness;
    //the guy said it is to uniquely identify vrf chainlink node
    enum LOTTERY_STATE{
        Open,
        Closed,
        Calculating_Winner
    }

    event RequestedRandomness(bytes32 requestId);

    LOTTERY_STATE lottery_state;

    constructor (
        address _priceFeedAddress, 
        address _vrfCoordinator, 
        address _link, 
        uint256 _fee, 
        bytes32 _keyhash
        ) public VRFConsumerBase(_vrfCoordinator, _link) {
        admin = msg.sender;
        //how are there multiple constructors here...
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.Closed;
        fee = _fee;
        keyhash = _keyhash;
        //fee is how much tokens we need for this thing to operate
    }
    function enter() public payable {
        //50$ minimum
        require(lottery_state == LOTTERY_STATE.Open,'Lottery is not open');
        require(msg.value >= getEntranceFee(), 'you need to put in more money');
        players.push(msg.sender);
    }
    function getEntranceFee() public view returns(uint256){
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * (10**10); // 18 decimals
        // $50, $2,000 / ETH
        // 50/2,000
        // 50 * 100000 / 2000
        uint256 costToEnter = (minimumUSDamt * 10**18) / adjustedPrice;
        return costToEnter;
        //this thing is returning a contract instance... 
        //recommended/must to use SafeMath when sending this code to production
    }
    function start_lottery() public onlyOwner{
        require(lottery_state == LOTTERY_STATE.Closed,'Cant open an ongoing lottery');
        lottery_state = LOTTERY_STATE.Open;
    }
    /*
    modifier OnlyAdmin() {
        require (msg.sender == admin);
        _;
    }
    */
    function end_lottery() public onlyOwner{
        // uint256(
        //     keccack256(
        //         abi.encodePacked(
        //             nonce, // nonce is preditable (aka, transaction number)
        //             msg.sender, // msg.sender is predictable
        //             block.difficulty, // can actually be manipulated by the miners!
        //             block.timestamp // timestamp is predictable
        //         )
        //     )
        // ) % players.length;

        //  so in the above thing there are random numbers in time, which are all predictable except block.difficulty which is 
        //manipulateable
        // and all of it is hashed together using keccak 256 algorithm, hence we can say that it is a random enough algorithm
        //but we cant use that onto the actual rpduct based code, due to maliciousness

        //Truly checks the randomness of the number, it is based off of an offchain random number generation, that is 
        //not based on API calls, since APIs can go down, and VRF also has real world product applications...
        // personal opinion - ig we cna trust it, 60% trustworthiness
        // 

        lottery_state = LOTTERY_STATE.Calculating_Winner;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
        //REQUEST AND RECIEVE FUNCTIONALITY

    }
    //possible that my thing was not working since mainnet`s port is at 8545 and not 7545, 
    //that is a property of the mainnet itself...

//add contents and description later...

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
//SO THISZ IS A CALLBACK function :

// rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call

  //basically this function mai hi the random number is returned, and the randomness is the random number that we desired
  //whatever we want to do with the random number is to be done/written here

        //INTERNAL - SINCE ONLY THE CHAINLINK NODES CAN CALL THIS FUNCTION
        //virtual-override thing..., ig we can add new functions to a derived contract
        require(
            lottery_state == LOTTERY_STATE.Calculating_Winner,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        //randomly gives a number which is within the index range...
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        // Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.Closed;
        randomness = _randomness;
        //resetting and storing of previous random number
    }

    function lottery_state_read()public view returns(uint256){
        return uint256(lottery_state);
    }
    function players_read()public view returns(address payable[] memory){
        return players;
    }
    function getwinner() public view returns(address payable){
        return recentWinner;
    }
}