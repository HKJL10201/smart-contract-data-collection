// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainLink_vrf/contracts/src/v0.6/VRFConsumerBase.sol";
import "@chainLink_V3/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openZeppelin/contracts/access/Ownable.sol";

contract Smart_lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public admin;
    address payable public recentWinner;
    uint256 public entranceFee;
    AggregatorV3Interface public priceFeed_obj;

    bytes32 public KeyHash;
    uint256 public fee;
    event RequestRandomness(requestID);

    enum StateOfLottery {
        open, closed, choosingWinner
    }
    StateOfLottery public state_of_lottery;

    constructor (
        address _vrfCoordinator, 
        address _link, 
        bytes32 _keyHash, 
        uint256 _fee, address _priceFeed) public VRFConsumerBase(_vrfCoordinator, _link) {
        priceFeed_obj= AggregatorV3Interface(_priceFeed);
        entrance_fee= 70*(10**18);
        admin= msg.sender;
        KeyHash= _keyHash;
        fee= _fee;
        state_of_lottery= StateOfLottery.closed;
    }
    
    function start_lottery() public onlyOwner
    {
        require(state_of_lottery== StateOfLottery.closed, "you are not there yet !!");
        state_of_lottery= StateOfLottery.open;
    }
    function end_lottery() public onlyOwner
    {
        require(state_of_lottery== StateOfLottery.open, 'lottery is inactive !!');
        state_of_lottery= StateOfLottery.choosingWinner;
        bytes32 requestId= requestRandomness(KeyHash, fee);
        emit RequestRandomness(requestId);
    }
    function fulfillRandomness(uint256 randomness, bytes32 requestId) internal override
    {
        require(state_of_lottery== StateOfLottery.choosingWinner, 'lottery is inactive !!');
        require(randomness>= 0);
        indexOf_Winner= randomness % players.length;
        recentWinner= players[indexOf_Winner];
        recentWinner.transfer(address(this).balance);
        players= new address payable[](0);
        state_of_lottery== StateOfLottery.closed;
        return recentWinner;
    }
    function entranceFee() public view returns(uint256)
    {
        require(state_of_lottery== StateOfLottery.open, 'lottery is inactive !!');
        (,int256 price_ethTo_usd,,,)= priceFeed_obj.latestRoundData();
        adjustedPrice= uint256(price_ethTo_usd)*10**10;
        priceToPay= (entrance_fee*10**18/adjustedPrice);
        return priceToPay;
    }
    function participate() payable public
    {
        require(state_of_lottery== StateOfLottery.open, 'lottery is inactive !!');
        require(msg.value>= entranceFee());
        players.push(msg.sender);
    }
}