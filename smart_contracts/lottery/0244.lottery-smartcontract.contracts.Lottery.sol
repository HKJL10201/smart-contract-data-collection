// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

// brownie will not able to understand with @chainlink means.
// So we need to remap it with what brownie will understand. This will be achieved in the brownie-config.yaml file

contract Lottery is Ownable, VRFConsumerBase {
    address payable[] public players;
    AggregatorV3Interface internal price_feed;
    uint256 public usdEntryFee;
    bytes32 public keyHash;
    uint256 public fee;
    uint256 internal randomNumber;
    address payable public winner;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    event RequestedRandomness(bytes32 requestId);

    LOTTERY_STATE public lottery_state;

    constructor(
        address _price_feed,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
        
    ) 
    public VRFConsumerBase(_vrfCoordinator, _link) {
        price_feed = AggregatorV3Interface(_price_feed);
        usdEntryFee = 50 * 10**18;
        lottery_state = LOTTERY_STATE.CLOSED;
        keyHash = _keyHash;
        fee = _fee;
    }

    function enter() public payable {
        //  User can only enter with 50 dollars and before you can enter, the admin must have started the lottery
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery must have been started before you enter");
        require(msg.value >= getEntranceFee(), "Not enough Ether");
        players.push(msg.sender);
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = price_feed.latestRoundData();
        return uint256(answer) * 10**10;
    }

    function getEntranceFee() public view returns (uint256) {
        // The goal here is to convert dollar to ether value
        uint256 ethPrice = getPrice();
        // // 50 dollars / 3757 dollars gives us 0.0133ETH (1 dollar) (assuming that 1 ETH = 3757 dollars)
        uint256 entranceFee = (usdEntryFee * 10**18) / ethPrice;
        // So, we are expecting something like
        return entranceFee;
    }

    function startLottery() public onlyOwner {
        // Before a lottery can be started, it must have been closed already
        require(lottery_state == LOTTERY_STATE.CLOSED);

        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        // Random number is generated here.

        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyHash, fee);  

        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override{
        // You can only obtain random number if we are currently calculating random number

        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "Not there yet");
        require(_randomness > 0, "Random number not found");

        randomNumber = _randomness;
        winner = players[_randomness % players.length];

        winner.transfer(address(this).balance);

        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;

    }


}
