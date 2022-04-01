// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public USDentryfee;
    AggregatorV3Interface internal ethUSDpriceFeed;
    enum LOTTERY_STATE {
        OPEN, //state 0
        CLOSED, //state 1
        CALCULATING_WINNER //state 2
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyHash;
    event RequestedRandomness(bytes32 requestID);

    constructor(
        address _priceFeedAdd,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        USDentryfee = 50 * (10**18);
        ethUSDpriceFeed = AggregatorV3Interface(_priceFeedAdd);
        lottery_state = LOTTERY_STATE.CLOSED; //can also write as lottery_state = 1
        fee = _fee;
        keyHash = _keyHash;
    }

    function enter() public payable {
        //require $50
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not Enough ETH!");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUSDpriceFeed.latestRoundData();
        uint256 AdjustedPrice = uint256(price) * (10**10); //18 decimal places
        uint256 costToEnter = (USDentryfee * (10**18)) / AdjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Ongoing Lottery in progress"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        // uint(
        //     keccak256(
        //         abi.encodePacked(
        //                 nonce,      //nonce is predictable (aka, txn number)
        //                 msg.sender,     //msg.sender is predictabe
        //                 block.difficulty,    //can actually be manipulated by miners!
        //                 block.timestamp     //timestamp is predictable
        //             )
        //         )
        //     ) % players.length;
        //blockchain is a deterministic system, so we need to look outside the blockchain to generate true random numbers.
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestID = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestID);
    }

    function fulfillRandomness(bytes32 _requestID, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random number not found!");
        uint256 indexofWinner = _randomness % players.length;
        recentWinner = players[indexofWinner];
        recentWinner.transfer(address(this).balance);
        //Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
