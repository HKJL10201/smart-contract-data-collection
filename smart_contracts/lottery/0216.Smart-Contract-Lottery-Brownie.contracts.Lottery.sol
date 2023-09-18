// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    constructor(address _priceFeedAddress, address _vrfCoordinator, address _link, uint256 _fee, bytes32 _keyhash 
    ) public VRFConsumerBase(_vrfCoordinator, _link){
        usdEntryFee=50 *(10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee =_fee;
        keyhash = _keyhash;
    }

    function enter() public payable{
        //$50 min
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not Neough Eth!");
        players.push(msg.sender);


    }
    function getEntranceFee() public view returns (uint256){
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData(); 
        //%50, $2000/ ETH
        //50/2000
        //50*100000 /2000
        uint256 adjustedPrice = uint256(price) *10 ** 10; //18 decimals
        uint256 costToEnter = (usdEntryFee * 10 ** 18) / adjustedPrice;
        return costToEnter;

    }
    function startLottery() public onlyOwner {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Cant start new lottery yet!" );
        lottery_state = LOTTERY_STATE.OPEN;

    }
    function endLottery() public onlyOwner{

        // require(lottery_state == LOTTERY_STATE.OPEN, "Cant end lottery thats not open");
        // lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        // pickWinner();

       // uint256(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp )))%players.length;

        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override{

        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You arent there yet!");
        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        //Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }

    // function pickWinner() {

    //     uint256 randomNumber = 
    // }


}