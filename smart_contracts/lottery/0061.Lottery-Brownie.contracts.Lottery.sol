//SPDX-License-Identifier:MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PriceFeedConsumer.sol";
import "./VRFConsumer.sol";

contract Lottery is Ownable, PriceFeedConsumer, VRFConsumer {

    enum LotteryStatus {Ended, Open, PickingWinner}
    LotteryStatus public status;

    event RequestedWithId(bytes32 requestId);

    address payable[] public players;
    address payable public recentWinner;
    uint256 public recentRandom;
    int256 public entryFeeUSD = 50;


    constructor(address _priceFeedAddress,
        bytes32 _keyhash,
        address _vrfCoordinator,
        address _linkToken,
        uint256 _fee)
    PriceFeedConsumer(_priceFeedAddress)
    VRFConsumer(_keyhash, _vrfCoordinator, _linkToken, _fee) public {
        status = LotteryStatus.Ended;
    }

    function getLotteryPriceInWei() public view returns (uint256) {
        int _price_per_eth = getLatestPrice();
        return uint256(1e18 * entryFeeUSD * 1e8 / _price_per_eth);
    }

    function enter() public payable {
        require(status == LotteryStatus.Open);
        require(msg.value >= getLotteryPriceInWei());
        players.push(payable(msg.sender));
    }

    function start() public onlyOwner {
        require(status == LotteryStatus.Ended);
        status = LotteryStatus.Open;
    }

    function end() public onlyOwner {
        require(status == LotteryStatus.Open);
        status = LotteryStatus.PickingWinner;
        bytes32 _requestId = getRandomNumber();
        emit RequestedWithId(_requestId);

    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        emit ReturnedRandomness(randomResult);
        recentRandom = randomness;

        recentWinner = players[randomness % players.length];
        recentWinner.transfer(address(this).balance);

        status == LotteryStatus.Ended;
        players = new address payable[](0);
    }

}