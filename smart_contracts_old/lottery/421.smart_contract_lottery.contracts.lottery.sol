//SPDX-License-Identifier:MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract lottery is VRFConsumerBase {
    address payable[] public players;
    address owner;
    address payable public recentWinner;

    uint256 public usdEntryFee;
    uint256 public randomness;
    uint256 public fee;

    AggregatorV3Interface internal priceFeed;
    Lottery_State public lottery_state;

    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    enum Lottery_State {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    constructor(
        address _priceFeedAddress,
        address _vrfcoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfcoordinator, _link) {
        usdEntryFee = 50 * 10**18;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = Lottery_State.CLOSED;
        owner = msg.sender;
        fee = _fee;
        keyhash = _keyhash;
    }

    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function enter() public payable {
        require(lottery_state == Lottery_State.OPEN);
        require(msg.value >= getEntranceFee(), "Poors Not Allowed!");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10;
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public _onlyOwner {
        require(lottery_state == Lottery_State.CLOSED);
        lottery_state = Lottery_State.OPEN;
    }

    function endLottery() public _onlyOwner {
        lottery_state = Lottery_State.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == Lottery_State.CALCULATING_WINNER,
            "You aren't there yet"
        );
        require(_randomness > 0, "random-not-found");

        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);

        //Reset
        players = new address payable[](0);
        lottery_state = Lottery_State.CLOSED;
        randomness = _randomness;
    }
}
