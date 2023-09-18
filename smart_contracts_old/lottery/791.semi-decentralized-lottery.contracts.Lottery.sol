//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase {
    enum LotteryState {
        Open,
        Closed,
        CalculatingWinner
    }

    address internal owner;
    uint256 internal fee;
    bytes32 internal keyhash;
    uint256 internal usdEntranceFee;
    AggregatorV3Interface internal ethToUSDPriceFeed;

    address payable[] public players;
    uint256 public randomness;
    address payable public recentWinner;
    LotteryState public lotteryState;
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        owner = msg.sender;
        usdEntranceFee = 50 * 10**18;
        lotteryState = LotteryState.Closed;
        ethToUSDPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        fee = _fee;
        keyhash = _keyhash;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "This action can only be done by the owner of this contract"
        );
        _;
    }

    function enter() external payable {
        require(
            lotteryState == LotteryState.Open,
            "Sorry, we're currently not opening a lottery"
        );
        require(
            msg.value >= getEntranceFee(),
            "You need to transfer a minimum of ETHs equal to 50 USD"
        );
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethToUSDPriceFeed.latestRoundData();

        uint256 evaluatedPrice = uint256(price * 10**10);

        uint256 entranceFee = (usdEntranceFee * 10**18) / evaluatedPrice;

        return entranceFee;
    }

    function startLottery() external onlyOwner {
        require(
            lotteryState == LotteryState.Closed,
            "Sorry, a lottery is still running"
        );
        lotteryState = LotteryState.Open;
    }

    function endLottery() external onlyOwner {
        lotteryState = LotteryState.CalculatingWinner;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32, uint256 _randomness) internal override {
        require(
            lotteryState == LotteryState.CalculatingWinner,
            "Currently not calculating any winner"
        );
        require(_randomness > 0, "Couldn't calculate a random number");

        // Setting a winner
        uint256 winnerIndex = _randomness % players.length;
        recentWinner = players[winnerIndex];
        recentWinner.transfer(address(this).balance);

        // Reset players
        players = new address payable[](0);
        lotteryState = LotteryState.Closed;
        randomness = _randomness;
    }
}
