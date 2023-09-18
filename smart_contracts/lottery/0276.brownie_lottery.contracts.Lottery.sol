// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    uint256 public entryFeeUSD;
    AggregatorV3Interface internal ethPricefeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint256 public feeForVRF;
    bytes32 public keyHashForVRF;
    address payable public recentWinner;
    uint256 public randomness;
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _pricefeedAddress,
        address _vrfcoordinatorAddress,
        address _link,
        uint256 _feeForVRF,
        bytes32 _keyHash
    ) public VRFConsumerBase(_vrfcoordinatorAddress, _link) {
        entryFeeUSD = 50 * (10**18);
        ethPricefeed = AggregatorV3Interface(_pricefeedAddress);
        feeForVRF = _feeForVRF;
        keyHashForVRF = _keyHash;
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function enterLottery() public payable {
        //require minimum amount
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "Sorry! Lottery is closed currently!"
        );
        require(
            msg.value >= getEntranceFee(),
            "Please increse the ETH amount!"
        );
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethPricefeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * (10**10);
        uint256 costToEnter = ((entryFeeUSD) * (10**18)) / adjustedPrice;
        return costToEnter;
    }

    function initLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyHashForVRF, feeForVRF);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "Error state mismatch!"
        );
        require(_randomness > 0, "Random number not found!");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        //Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
