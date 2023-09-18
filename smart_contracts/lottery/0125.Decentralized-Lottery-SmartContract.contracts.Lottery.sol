// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

// importing owable contract which is not deployed so no nned for address as in the case of aggregatorv3interface
contract Lottery is Ownable, VRFConsumerBase {
    uint256 public entryfee;
    AggregatorV3Interface internal ethpricefeed;
    AggregatorV3Interface internal ethpricefeedINR;

    bytes32 public keyHash;
    uint256 public fee;
    uint256 public WinnerIndex;
    address payable public recentWinner;

    constructor(
        address _pricefeedusd,
        // address _priceFeedINRToUSD,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        entryfee = 50 * 10**18;
        ethpricefeed = AggregatorV3Interface(_pricefeedusd);
        //ethpricefeedINR = AggregatorV3Interface(_priceFeedINRToUSD);
        keyHash = _keyHash;
        fee = _fee;
    }

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        COMPUTING_WINNER
    }

    event RequestedRandomness(bytes32 requestId);

    LOTTERY_STATE public lottery_state = LOTTERY_STATE.CLOSED;

    address payable[] public players;

    function Enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery has ended");
        require(msg.value > getEntranceFee(), "Not enough eth");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        //500 rs

        // (, int256 price, , , ) = ethpricefeed.latestRoundData();
        //uint256 updatedprice = uint256(price) * 10**10;

        //(, int256 priceINR, , , ) = ethpricefeedINR.latestRoundData();
        //uint256 priceINRToETH = (uint256(priceINR) * 10**10 * entryfee) /
        //  updatedprice;
        //return priceINRToETH;

        (, int256 price, , , ) = ethpricefeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        // $50, $2,000 / ETH
        // 50/2,000
        // 50 * 100000 / 2000
        uint256 costToEnter = (entryfee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function StartLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function StopLottery() public {
        require(lottery_state == LOTTERY_STATE.OPEN, "lottery is closed");
        lottery_state = LOTTERY_STATE.COMPUTING_WINNER;
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestId);
    }

    //internal so that only link node can call this function

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.COMPUTING_WINNER,
            "not there yet"
        );
        WinnerIndex = _randomness % players.length;
        require(_randomness > 0, "random not found");
        recentWinner = players[WinnerIndex];
        recentWinner.transfer(address(this).balance);
        //reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
    }
}
