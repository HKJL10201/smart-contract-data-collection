// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    // address payable is a data type that gives additional functionality to the stored user address such asuser.send(), user.transfer() and user.call()
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethusdPriceFeed;
    enum LOTTERY_STATES {
        OPEN, // 0
        CLOSED, // 1
        CALCULATING_WINNER // 2
    }
    LOTTERY_STATES public lottery_state;
    uint256 public fee;
    bytes32 public keyHash;
    event RequestedRandomness(bytes32 requestID);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * 10**18; // $50
        ethusdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATES.CLOSED;
        fee = _fee;
        keyHash = _keyHash;
    }

    function enter() public payable {
        require(
            lottery_state == LOTTERY_STATES.OPEN,
            "The lottery has not opened yet!"
        );
        require(
            msg.value >= getEntranceFee(),
            "Not enough ETH to enter the lottery :("
        );
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 _price, , , ) = ethusdPriceFeed.latestRoundData();
        // Converting int256 to uint256 and
        // price has 8 decimals, converting that to 18 decimals by multiplying 10**10
        uint256 price = uint256(_price) * 10**10;
        // costToEnter(in eth) = $50 / Price of one eth in USD
        // costToEnter(in wei) = costToEnter(in eth) * 10**18
        uint256 costToEnter = (usdEntryFee * 10**18) / price; // Cost to enter in wei
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATES.CLOSED,
            "Cannot start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATES.OPEN;
    }

    function endLottery() public onlyOwner {
        // The code below generates a 'pseudorandom' number => Do not use this for an actual application
        // keccak(256) always hashes the same way
        // uint256(
        //     keccak256(
        //         abi.encodePacked(
        //             nonce, // Predictable
        //             msg.sender, // Predictable
        //             block.difficulty, // Can be manipulated by miners
        //             block.timestamp // Predictable
        //         )
        //     )
        // ) % players.length;
        lottery_state = LOTTERY_STATES.CALCULATING_WINNER;
        bytes32 requestID = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestID);
    }

    function fulfillRandomness(bytes32 _requestID, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATES.CALCULATING_WINNER,
            "You must be calculating the winner in order to use this function!"
        );
        require(_randomness > 0, "Random number was not generated properly!");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);

        // Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATES.CLOSED;
        randomness = _randomness;
    }
}
