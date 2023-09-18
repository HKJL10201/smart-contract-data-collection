// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";


contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public usdEnteryFee;
    uint256 public randomness;
    uint256 public fee;
    bytes32 public keyHash;
    event RequestRandomness(bytes32 requestId);

    AggregatorV3Interface internal ethUSDPriceFeed;
    enum LOTTERY_STATE{
        OPEN, 
        CLOSED,
        CALCULATING_WINNER 
    }

    LOTTERY_STATE public lotteryState;

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
        ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEnteryFee = 50* (10**18);
        ethUSDPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lotteryState = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyHash = _keyHash;
    }

    
    function enter() public payable{
        // 50$ minimum
        require(lotteryState == LOTTERY_STATE.OPEN, 'Lottery is not Open yet!!!');
        require(msg.value >= getEntranceFee(), 'NOT Enough USD!!!');
        players.push((msg.sender));

    }

    function getEntranceFee() public view returns(uint256){
        (, int256 price, ,,) = ethUSDPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price)* 10**10; // 18 decimals
        uint256 costToEnter = (usdEnteryFee* 10**18)/adjustedPrice;
        return costToEnter;
    }
    function startLottery() public onlyOwner{
        require(
        lotteryState == LOTTERY_STATE.CLOSED,
        'Can Not start a new lottery yet!!'
        );
        lotteryState = LOTTERY_STATE.OPEN;

    }
    function endLottery() public onlyOwner{
        // uint256(
        //    keccak256(
        //        abi.encodePacked(
        //            nonce,
        //            msg.sender,
        //            block.difficulty,
        //            block.timestamp
        //        )
        //    )
        //);
        lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RequestRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override{
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER,
        'You are not there yet!!'
        );
        require(_randomness>0,
        'Random not found!!'
        );

        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        // reset:
        players = new address payable[](0);
        lotteryState = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}