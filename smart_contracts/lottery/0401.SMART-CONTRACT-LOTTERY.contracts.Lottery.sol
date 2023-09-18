pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {OPEN, CLOSED, CALCULATING_WINNER}
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    event requestedRandomness(bytes32 requestId);
    

    constructor(address _priceFeedAddress, address _vrfCoordinator, address _link, uint256 _fee, bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery have not start yet");
        // $50 minimum
        require(msg.value >= getEntranceFee(), "Not enough Eth");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        //get price 
        (,int price, , , ) = ethUsdPriceFeed.latestRoundData();
        //convert int
        uint256 ajustedPrice = uint256(price) * 10**10; //8 decimal_feed +10 = 18 decimals
        //$50, $2000/ETH
        //50/2000
        // 50 * 100000 / 2000
        uint256 costToEnter = (usdEntryFee * 10**18) / ajustedPrice;
        return costToEnter;
        //this method above is a very bad method to do math. Uses SafeMath instead
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        // Randomness
        
        // Tryna get random number on chain
        // uint(keccak256(
        //    abi.encodePacked(
        //        msg.sender, // is predictable
        //        block.difficulty, // can be manipulated by the miners
        //        block.timestamp // is predictable
        //    )
        // )) % players.length; // this is a very bad method to generate random number in our lottery 

        // it's better to look outside the blockchain can't use API also
        
        // chainlink VRF provides verifiable Randomness
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit requestedRandomness(requestId);

    }
    // Chainlink already have a function name fulfillrandomness so we have to override it
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You are not there yet");
        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        //reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;

    }
}