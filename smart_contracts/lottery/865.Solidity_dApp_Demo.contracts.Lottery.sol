// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";

contract Lottery is Ownable, VRFConsumerBase {
    address payable[] public players;
    address payable public recentWinner;
    uint public usdPrice = 5 * 10 ** 18;
    uint public result;

    enum State {Open, Close, Entered, Calculating}
    State public state;

    bytes32 public keyHash;
    uint public vrfFee;
    uint256 public randomness;

    AggregatorV3Interface internal priceFeed;
    constructor(address _priceFeed, address _vrfCoordinator, address _link, bytes32 _keyHash, uint _vrfFee) VRFConsumerBase(_vrfCoordinator, _link) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        state = State.Close;
        keyHash = _keyHash;
        vrfFee = _vrfFee;
    }

    function enter() public payable {
        require(msg.value >= getEntryFee());
        require(state == State.Open);
        players.push(payable(msg.sender));
        state = State.Entered;
    }

    function getEntryFee() public view returns(uint) {
        (, int price,,,) = priceFeed.latestRoundData();
        return uint((usdPrice * 10 ** 8) / uint(price));
    }

    function start() public onlyOwner {
        require(state == State.Close);
        state == State.Open;
    }

    function end() public onlyOwner {
        require(state == State.Entered);
        state = State.Calculating;
        bytes32 reqId = requestRandomness(keyHash, vrfFee);
        fulfillRandomness(reqId, randomness); 
        recentWinner = players[result];
        recentWinner.transfer(address(this).balance);
        players = new address payable[](0);
        state = State.Close;
    }

    function fulfillRandomness(bytes32 _reqId, uint256 _randomness) internal override {
        require(state == State.Calculating);
        require(_randomness > 0);
        result =  _randomness % players.length;
    }
}