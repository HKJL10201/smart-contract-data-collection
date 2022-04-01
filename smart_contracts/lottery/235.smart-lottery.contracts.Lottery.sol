pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is Ownable, VRFConsumerBase{

    address payable[] public players;
    address payable public recentWinner;
    uint public usdEntryFee;
    uint public randomness;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);


    constructor(address _priceFeedAddress, address _vrfCoordinator, address _link, uint _fee, bytes32  _keyhash)
        public  VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _link
        ) {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface( _priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;// LINK Token
        keyhash = _keyhash;

    }

    function enter() public payable{
        // $50 min
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery Closed");
        require(msg.value >= getEntryFee(), "Not Enough ETH");
        players.push(payable(msg.sender));
    }
    function getEntryFee() public view returns (uint256) {
        (
            ,
            int price,
            ,
            ,

        ) = ethUsdPriceFeed.latestRoundData();
        uint adjustedPrice = uint(price) * 10**10;
        uint costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }
    function startLottery() public onlyOwner {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Lottery already Open");
        lottery_state = LOTTERY_STATE.OPEN;

    }
    function endLottery() public onlyOwner{
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);

    }
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You arent there yet"
        );
            require(_randomness > 0, "No _randomness found");
            uint indexOfWinner = _randomness % players.length;
            recentWinner = players[indexOfWinner];

            recentWinner.transfer(address(this).balance);

            // Reset players
            players = new address payable[](0);
            lottery_state = LOTTERY_STATE.CLOSED;
            randomness = _randomness;
    }
}
