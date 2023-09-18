pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract Lottery {
    address payable[] public players;
    uint256 public usdENtryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LotteryState {
OPEN,
CLOSED,
CALCULATING_WINNER
    }
    LotteryState public lotterystates;

    
    //0
    //1
    //2

    constructor(address _priceFeedAddress) public {
        usdENtryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lotterystates =LotteryState.CLOSED;
        
    }

    function enter() public payable {
        require(lotterystates == LotteryState.CLOSED ,"LotteryNot opened yet");
        require(msg.value>= getEntranceFee(),"Not enough Ether");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (,int price,,,)=ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10;
        uint256 costtoenter = usdENtryFee*10**18/adjustedPrice;
        return costtoenter;

    }

    function startLottery() public {
        require();


    }

    function endLottery() public {}
}
