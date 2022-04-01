//  SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

// import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    uint256 usdEntryFee = 50;
    address payable public recentWinner;
    uint256 public randomness;
    AggregatorV3Interface internal ethUsdPricefeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    // OPEN - 0
    // CLOSED - 1
    // CALCULATING_WINNER - 2
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
        ethUsdPricefeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED; // state is closed when the lottery is starting...
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        // minimum $50 for a player
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntryFee(), "Sorry, Not enough ETH!");
        players.push(payable(msg.sender));
    }

    function getEntryFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPricefeed.latestRoundData();
        uint256 adjestedPrice = uint256(price) * 10**10; // 18 decimals => (ETH/USD has 8 decimals)
        uint256 costToEnter = (usdEntryFee * 10**18) / adjestedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start another new lottery yet!!! "
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        // ! this is a very bad way to pick a random winener...
        // uint256(
        //     keccak256(
        //         abi.encodePacked(
        //             nonce, // this is predictable -> (transaction number)
        //             msg.sender, // this is predictable -> sender
        //             block.difficulty, // this can be manipulated by the miners.
        //             block.timestamp // this is predictable
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
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "Your'e not there yet!"
        );
        require(_randomness > 0, "random-not-found!!!");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        // resetting the lottery after the end of the game
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
