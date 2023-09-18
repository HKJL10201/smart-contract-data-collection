// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";


contract Lottery is VRFConsumerBase,Ownable{

    address payable[] public players;
    uint256 public usdEntryFee ;
    address payable public recentWinner;
    uint256 public randomness ;
    AggregatorV3Interface internal ethUsdPriceFeed ;
    enum LOTTERY_STATE {
        OPEN , 
        CLOSED , 
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state ;
    uint256 public fee ;
    bytes32 public keyhash ;

    constructor(
        address _priceFeedAddress , 
        address _vrfCoordinator , 
        address _link,
        uint256 _fee ,
        bytes32 _keyhash
    ) 
        public
        VRFConsumerBase(_vrfCoordinator , _link)
    {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;

    }


    function enter() public payable {
        // 50 $ minimum
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value > getEntranceFee() , "plese enter more then 50$ in ethet "  );
        players.push(msg.sender);

    }

    function getEntranceFee() public view returns(uint256) {
        ( , int256 price ,,,) = ethUsdPriceFeed.latestRoundData();
        // 50$ , $2000 /ETH 
        // 50 /2000  
        uint256 adjustedPrice = uint256(price) *10**10 ;
        uint costToEnter = (usdEntryFee * 10**18)/adjustedPrice;
        return costToEnter;



    }
    function startLottery() public onlyOwner {
        
        require(lottery_state == LOTTERY_STATE.CLOSED , "Can't start a new Lottery");
        lottery_state = LOTTERY_STATE.OPEN;

                                            
    }
    function endLottery() public onlyOwner {

        // random no generator 

        // uint256(
        //     keccack256(
        //         abi.encodePacked(
        //             nonce , 
        //             msg.sender , 
        //             block.difficulty, 
        //             block.timestamp
        //         )
        //     )
        // )%players.length;
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash ,fee);

    }
    function  fulfillRandomness(bytes32 _requestId , uint _randomness) internal override {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER , "you are not there yet!");
        require(_randomness >0 , "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = payable(players[indexOfWinner]);
        recentWinner.transfer(address(this).balance);
        // Reset 
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;

    }
}