pragma solidity ^0.6.6;
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase,Ownable{

    address payable[] public players;
    address payable public recentWinner;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    uint256 public fee;
    bytes32 public keyHash;
    uint256 randomness;
    enum LOTTERY_STATE{
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    event RequestedRandomness(bytes32 requestId);
    constructor(address _priceFeed,
     address _vrfCoordinator,
     address _link,
     uint256 _fee,
     bytes32 _keyhash
     ) 
     
    public VRFConsumerBase(_vrfCoordinator,_link) {
        usdEntryFee=50 * (10**18);
        ethUsdPriceFeed=AggregatorV3Interface(_priceFeed);
        lottery_state=LOTTERY_STATE.CLOSED;
        fee=_fee;
        keyHash=_keyhash;
    }
    function enter() public payable{
        require(lottery_state==LOTTERY_STATE.OPEN,"Lottery not started");
        require(msg.value>=getEntranceFee(),"Not enough eth");
        players.push(msg.sender);
    }
    function getEntranceFee() public view returns (uint256){
        (,int price,,,)=ethUsdPriceFeed.latestRoundData();
        uint256 adjustPrice=uint256(price) * 10**10;
        uint256 costToEnter=(usdEntryFee * 10**18)/adjustPrice;
        return costToEnter;
    }
    function startLottery() public onlyOwner{
        require(lottery_state==LOTTERY_STATE.CLOSED,"Cannot start a new lottery");
        lottery_state=LOTTERY_STATE.OPEN;
    }
    function endLottery() public onlyOwner{
    //     uint(
    //         keccak256(
    //             abi.encodePacked(
    //                 nonce,
    //                 msg.sender,
    //                 block.difficulty,
    //                 block.timestamp
    //     ))) % players.length;
    // }
    lottery_state=LOTTERY_STATE.CALCULATING_WINNER;
    bytes32 requestId=requestRandomness(keyHash,fee);
    emit RequestedRandomness(requestId);
    }
    function fulfillRandomness(bytes32 _requestId,uint256 _randomness) internal override{
        require(lottery_state==LOTTERY_STATE.CALCULATING_WINNER,"yOUR ARENT THERE");
        require(_randomness>0,"random-not-found");
        uint256 indexOfWinner=_randomness % players.length;
        recentWinner=players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        players=new address payable[](0);
        lottery_state=LOTTERY_STATE.CLOSED;
        randomness=_randomness;
    }
}