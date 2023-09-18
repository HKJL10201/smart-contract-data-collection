// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase {

    enum LotteryState {
        CLOSED,
        OPEN,
        CALCULATING_WINNER
    }

    uint256 constant DECIMALS = 18;
    uint256 public maxPlayers;
    address payable[] public players;
    uint256 public usdEntryFee;
    AggregatorV3Interface ethUsdPriceFeed;
    LotteryState private lotteryState;
    address payable public winner;
    uint256 public randomness;
    uint256 public linkFee;
    bytes32 public keyhash;

    constructor(
        uint256 _maxPlayers, 
        uint256 _usdEntryFee, 
        address _priceFeedAddress, 
        address _vrfCoordinator,
        address _link, 
        uint256 _linkFee, 
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = convertToCorrectDecimals(_usdEntryFee, 0);
        maxPlayers = _maxPlayers;
        lotteryState = LotteryState.OPEN;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        linkFee = _linkFee;
        keyhash = _keyhash;
    }

    function enterLottery() public payable returns(bool) {
        require(lotteryState == LotteryState.OPEN, "Lottery is currently closed!");
        require(convertToCorrectDecimals(msg.value, 18) >= getEntranceFee(), 
                string(abi.encodePacked("Not enough ETH, Entrance fee should be greater than or equal to ", getEntranceFee()))
        );
        
        players.push(payable(msg.sender));
        if (players.length == maxPlayers) {
            endLottery();
        }
        
        return true;
    }

    function getEntranceFee() public view returns(uint256) {
        (, int price,,,) = ethUsdPriceFeed.latestRoundData() ;
        uint256 oneEthInUsd = convertToCorrectDecimals(uint256(price), ethUsdPriceFeed.decimals());
        uint256 entranceFee = convertToCorrectDecimals(usdEntryFee, 0) / oneEthInUsd;
        return entranceFee;
    }

    function startLottery() private {
        lotteryState = LotteryState.OPEN;
    }
    
    function endLottery() private {
        lotteryState = LotteryState.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, linkFee);

        startLottery();
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(
            lotteryState == LotteryState.CALCULATING_WINNER,
            "LotteryState must be CALCULATING_WINNER"
        );
        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;

        winner = players[indexOfWinner];
        winner.call{value: address(this).balance}("");

        // Reset
        players = new address payable[](0);
        lotteryState = LotteryState.CLOSED;
        randomness = _randomness;
    }

    function convertToCorrectDecimals(uint256 num, uint256 currentDecimals) pure public returns(uint256) {
        if (DECIMALS < currentDecimals) {
            num = num / 10 ** (currentDecimals - DECIMALS);
        } else {
            num = num * 10 ** (DECIMALS - currentDecimals); 
        }
        return num;
    }

    function getLotteryState() view public returns(string memory) {
        if (lotteryState == LotteryState.OPEN) {
            return "OPEN";
        } else if (lotteryState == LotteryState.CLOSED) {
            return "CLOSE";
        } else {
            return "CALCULATING WINNER";
        }
    }
}