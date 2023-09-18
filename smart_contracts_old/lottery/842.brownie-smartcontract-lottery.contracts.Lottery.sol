// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable, VRFConsumerBase {
    AggregatorV3Interface internal priceFeed;
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    bytes32 internal keyHash;
    uint256 internal fee;
    event RequestedRandomness(bytes32 requestId);

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    LOTTERY_STATE public lotteryState;
    uint256 public usdEntreeFee;

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinatorAddress,
        address _vrfLinkToken,
        uint256 _fee,
        bytes32 _keyHash
    )
        VRFConsumerBase(
            _vrfCoordinatorAddress, // VRF Coordinator
            _vrfLinkToken // LINK Tokenol
        )
    {
        usdEntreeFee = 50 * (10**18);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        lotteryState = LOTTERY_STATE.CLOSED;
        keyHash = _keyHash;
        fee = _fee;
    }

    function enter() public payable {
        // Minimum $50
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery is not open!");
        require(msg.value >= getEntranceFee(), "Not enough ETH!!!");
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // Multiply with 10**10 to make it equivanlent of 18 decimals
        uint256 adjustedPrice = uint256(price) * 10**10;
        uint256 entranceFee = (usdEntreeFee * 10**18) / (adjustedPrice);
        return entranceFee;
    }

    function startLottery() public onlyOwner {
        require(
            lotteryState == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery while an existing lottery is open!"
        );
        lotteryState = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        // uint256 winnerIndex = uint256(
        //     keccak256(
        //         abi.encodePacked(
        //             nonce, // predictable
        //             msg.sender, // predictable
        //             block.difficulty, // can be manipulated by miners
        //             block.timestamp // predictable
        //         )
        //     )
        // ) % players.length;
        //
        // require(
        //     lotteryState == LOTTERY_STATE.OPEN,
        //     "Can't close a lottery that is not open!"
        // );
        // lotteryState = LOTTERY_STATE.CLOSED;
        //
        lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = getRandomNumber();
        emit RequestedRandomness(requestId);
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lotteryState == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "Random not found!");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        // Now reset the lottery
        players = new address payable[](0);
        lotteryState = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
