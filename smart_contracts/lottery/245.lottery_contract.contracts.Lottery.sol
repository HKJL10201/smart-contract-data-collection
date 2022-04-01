// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is Ownable, VRFConsumerBase {
    address payable[] public players;
    address payable public recentWinner;
    uint256 randomness;
    uint256 usdEntryFee;
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

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18);
        fee = _fee;
        keyhash = _keyhash;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    modifier validState(LOTTERY_STATE _state) {
        require(lottery_state == _state, "invalid stage");
        _;
    }

    function enter() public payable validState(LOTTERY_STATE.OPEN) {
        // $50 minimum
        require(msg.value >= getEntranceFee(), "Not Enough ETH");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 price = getPrice() * 10**10; // 18 decimals
        uint256 costToEnter = (usdEntryFee * 10**18) / price;
        return costToEnter;
    }

    function startLottery() public onlyOwner validState(LOTTERY_STATE.CLOSED) {
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        // uint256(
        //     keccak256(
        //         abi.encodePacked(
        //             nounce, // nonce is predictable (aka, transaction number)
        //             msg.sender, // msg.sender is predictable
        //             block.difficulty, // can actually manipulated by the miners
        //             block.timestamp // timestamp is predictable
        //         )
        //     )
        // ) % players.length;
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
        validState(LOTTERY_STATE.CALCULATING_WINNER)
    {
        require(_randomness > 0, "ramdom-not-found");
        randomness = _randomness;
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        // reset players
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        // transfer eth to winner
        recentWinner.transfer(address(this).balance);
    }

    function getPrice() internal view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        return uint256(price);
    }
}
