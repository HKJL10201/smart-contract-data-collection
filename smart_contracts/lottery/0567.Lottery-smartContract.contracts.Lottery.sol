// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is Ownable, VRFConsumerBase {
    address payable[] public players;
    address payable public admin;
    address payable public recentWinner;
    uint256 public entrance_fee;
    uint256 public randomness;
    AggregatorV3Interface public priceFeeds;
    
    enum StateOf_lottery {
        open, closed, chooseTheWinner
    }
    StateOf_lottery public stateOf_lottery;

    bytes32 public KeyHash;
    uint256 public fee;
    event RequestRandomness(bytes32 requestID);

    constructor(address _priceFeedAddress, address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee) public VRFConsumerBase(_vrfCoordinator,_link) {
        // _link
        // address vrfCoordinator,
        entrance_fee = 50*10**18; // 50 usd
        priceFeeds= AggregatorV3Interface(_priceFeedAddress);
        KeyHash= _keyHash;
        fee= _fee;
        stateOf_lottery= StateOf_lottery.closed;
    }

    function startLottery() public onlyOwner {
        require(stateOf_lottery== StateOf_lottery.closed);
        stateOf_lottery= StateOf_lottery.open;
    }

    function endLottery() public onlyOwner {
        require(stateOf_lottery== StateOf_lottery.open);
        stateOf_lottery== StateOf_lottery.chooseTheWinner;
        bytes32 requestID= requestRandomness(KeyHash, fee);
        emit RequestRandomness(requestID);
    }

    function entranceFee() public view returns(uint256) {
        require(stateOf_lottery== StateOf_lottery.open);
        (,int256 single_ethTo_usd,,,)= priceFeeds.latestRoundData(); // 8 digit precision
        uint256 adjustedPrice= uint256(single_ethTo_usd) *10**10; // price of 1 eth with 18 digit precision
        uint256 price= (entrance_fee *10**18)/adjustedPrice;
        return price;
    }
    function enter() payable public {
        require(stateOf_lottery== StateOf_lottery.open, "lottery isn't active");
        require(msg.value>= entranceFee(), "not enough eth!");
        players.push(msg.sender);
    }
    function fulfillRandomness(bytes32 requestID, uint256 _randomness) internal override{
        require(stateOf_lottery== StateOf_lottery.chooseTheWinner);
        require(_randomness>=0);
        randomness= _randomness;
        uint256 indexOf_winner= (randomness % players.length);
        recentWinner= players[indexOf_winner];
        recentWinner.transfer(address(this).balance);   
        // 
        players= new address payable[](0);
        stateOf_lottery== StateOf_lottery.closed;
    }
}
