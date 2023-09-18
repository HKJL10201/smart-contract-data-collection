pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@OpenZeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is Ownable, VRFConsumerBase {

AggregatorV3Interface internal priceFeed;
uint256 ENTRANCE_FEE_USD=10*10**18;
address payable[] public gamblers;
address payable public recentWinner;
enum LOTTERY_STATE{
    OPEN,
    CLOSED,
    CALCULATING
}
LOTTERY_STATE public lotteryState;
uint256 fee;
bytes32 keyHash;
uint randnumber;



constructor(address _priceFeedAddress, address _VRFCoordinator, address Link_Token, uint256 _fee, bytes32 _keyHash )
             public VRFConsumerBase( _VRFCoordinator, Link_Token) 
{
    lotteryState=LOTTERY_STATE.CLOSED;
    priceFeed = AggregatorV3Interface(_priceFeedAddress);
    keyHash = _keyHash;
    fee = _fee; // 0.1 LINK (Varies by network)
}

function getEntranceFee() public view returns(uint256){
       (/*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        uint256 priceFee=uint256(price);
        uint256 adjustedPrice=priceFee*10**10;
        uint256 entrancefee=(ENTRANCE_FEE_USD*10**18)/adjustedPrice;
        //entrance fee is 10 usd

        return entrancefee;
}


function startLottery() onlyOwner public {
    require(lotteryState != LOTTERY_STATE.CLOSED, 'Cant start new lottey yet !!');
    lotteryState=LOTTERY_STATE.OPEN;
}

function enterLottery() public payable {
    require(msg.value >= getEntranceFee(), 'insufficient funds. Min is 10 usd');
    require(lotteryState == LOTTERY_STATE.OPEN, 'Lottery is closed');
    gamblers.push(msg.sender);
}

function endLottery() onlyOwner public{
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 requestID = requestRandomness(keyHash, fee);
        lotteryState=LOTTERY_STATE.CALCULATING;
}

function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        
        uint256 randomResult = randomness;
        require(randomResult > 0, 'Random result not found');
        uint256 indexWinner=randomResult % gamblers.length;
        recentWinner=gamblers[indexWinner];
        recentWinner.transfer(address(this).balance);
        gamblers=new address payable[](0);
        lotteryState = LOTTERY_STATE.CLOSED;
        randnumber=randomResult;

}
}