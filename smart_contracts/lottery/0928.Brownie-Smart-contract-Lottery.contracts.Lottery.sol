// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is Ownable, VRFConsumerBase {
    address payable[] public players;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdpriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyHash;
    address public recentWinner;
    uint256 public randomness;
    event RequestedRandomness (bytes32 requestId);

    // keyhash is a way to uniquely identify VRF node

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18); // 18 decimals
        ethUsdpriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyHash = _keyHash;
    }

    /*
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Access to this function is restricted to only owner"
        );
        _;
    }
    */

    function enter() public payable {
        // $50 minimum
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "The lottery hasn't begun yet!"
        );
        require(
            msg.value > getEntranceFee(),
            "Not enough ETH ma boi!, Send $50 worth Eth or more"
        );
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdpriceFeed.latestRoundData();
        // To get price 50* somebignumber / eth price
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
        // 0.033
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "The lottery state has to be closed!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        // uint256(
        //     keccak256(
        //         abi.encodePacked(
        //             nonce,
        //             msg.sender, // is predictable
        //             block.difficulty, // can be manipulated by miners
        //             block.timestamp // timestamp is predictable
        //         )
        //     )
        // ) % players.length;

        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random not found!");
        uint256 indexOfWinner = _randomness % players.length;
        // To declare winner
        recentWinner = players[indexOfWinner];
        // To pay the winner
        payable(recentWinner).transfer(address(this).balance);
        // to reset the lottery
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
