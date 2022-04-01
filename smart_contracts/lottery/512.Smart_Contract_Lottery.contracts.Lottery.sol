// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is VRFConsumerBase, Ownable {
    // explaining address payable:
    // https://ethereum.stackexchange.com/questions/64108/whats-the-difference-between-address-and-address-payable
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public USDEntryFee;
    AggregatorV3Interface internal ethUSDPriceFee;
    // enumerator
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    } // OPEN = 0, CLOSED = 1, CALCULATING_WINNER = 2
    LOTTERY_STATE public lottery_state;
    uint256 internal fee; // fee is Link token needed to pay for the request
    // we recieve random number and in return pay an oracle fee
    bytes32 internal keyHash; // keyHash is a way to uniquely identify chainlink VRF node
    event RequestedRandomness(bytes32 requestId);

    /* 
    EVENT: events are pieces of data executed on the blockchain and stored on the 
           blockchain but are not accessible by smart contracts, think of them as 
           print lines of blockchain
    */

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        //VRFConsumerBase constructor added
        USDEntryFee = 50 * (10**18); // 50$
        ethUSDPriceFee = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyHash = _keyHash;
    }

    function enter() public payable {
        // 50$ minimum
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        // entrance fee is 50$
        (, int256 price, , , ) = ethUSDPriceFee.latestRoundData();
        uint256 adjustedPrice = uint256(price) * (10**10); // because ETH/USD has 8 decimals (check chainlink)
        // we will multiply it with just 10^10 so that we have 18 decimals
        // 50 * 10^18 * 10^18 / 2000 * 10^18 -> units in wei
        uint256 costToEnter = (USDEntryFee * (10**18)) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new Lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyHash, fee); // request the data from chainlink oracle
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "Not there yet!"
        );
        require(_randomness > 0, "random not found");

        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        //Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }

    // my function
    function getArrayLength() public view returns (uint256) {
        return players.length;
    }
}
