// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
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
    address payable public recentWinner;
    uint256 randomness;
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * 10**8;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    // this is the function where user
    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(
            msg.value >= getEntranceFee(),
            "The minimum fee to enter the lottery is not satisfied."
        );
        players.push(msg.sender);
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = ethUsdPriceFeed.latestRoundData();
        return uint256(answer);
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 price = getPrice();
        uint256 precision = 1 * 1e18;
        return (usdEntryFee * precision) / price;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet."
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        // dangerous way to generate random number
        // since the hashing algo is determined, our randomness is only determined by encoded information packed in
        /*
        uint256(
            keccak256(
                abi.encodePacked(
                    nonce,  // nonce is predictable (aka transaction numbers)
                    msg.sender, // predictiable
                    block.difficulty, // can actually be manipulated by the minners
                    block.timestamp // timestamp is predictable
                )
            )
        ) % players.length;
        */

        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "you are on the wrong stage."
        );
        require(_randomness > 0, "random not found");
        randomness = _randomness;
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        // Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
    }
}
