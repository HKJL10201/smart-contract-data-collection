// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";


contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    uint256 public usdEntryFee;
    uint256 public randomness;
    address payable public recentWinner; 

    AggregatorV3Interface internal ethUsdPriceFee;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    // open is gen 1, closed is gen 2, calc is gen 3

    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);



    constructor(
        address _priceFeedAddress, 
        address _vrf_coordinator, 
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrf_coordinator, _link) {

        usdEntryFee = 50 * (10**18);
        ethUsdPriceFee = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;

    }

    function enter() public payable {
        // set $50 minimum
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH!");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFee.latestRoundData();
        uint256 adjusted_price = uint256(price) * 10**10; // 18 decimals

        uint256 cost_to_enter = (usdEntryFee * 10**18) / adjusted_price;
        return cost_to_enter;

        // $50
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        // uint256(
        //     keccack256(
        //         abi.encodePacked(
        //         nonce, // nonce is predictable(aka, transaction number)
        //         msg.sender, // msg.sender is predictable
        //         block.difficulty, // can be manipulated by miners
        //         block.timestamp // timestap is predictable
        //         )
        //     )
        // ) % players.length ;

        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash,fee);

        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness (bytes32 _requestId, uint256 _randomness) internal override {
        require (lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You are not there yet!");

        require(_randomness > 0, "random-not-found");
        uint256 indexofWinner = _randomness % players.length;
        recentWinner = players[indexofWinner];
        
        recentWinner.transfer(address(this).balance);

        //REset the lottery
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }

}
