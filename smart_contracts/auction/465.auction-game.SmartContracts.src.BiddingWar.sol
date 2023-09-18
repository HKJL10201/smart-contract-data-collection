//SPDX-License-Identifier: LICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SafeMath.sol";

contract BiddingWar is Ownable {
    using SafeMath for uint256;
    uint256 public bidEndTime = 60 minutes;
    uint256 public maxBidInterval = 10 minutes; //10 minutes;
    uint256 public commission = 50; // 50 = 5%
    bool public startBidding = false;
    uint256 public startTime;
    uint256 public curBidAmount;
    uint256 public curBidTime;
    address public lastBidder;
    uint256 public gameIndex = 0;
    uint256 private _totalCommissionAmount;
    uint256 public totalWinnerAmount = 0;

    modifier gameRunning() {
        require(checkGameRunning(), "game ended");
        _;
    }
    modifier gameEnded() {
        require(!checkGameRunning(), "game is running");
        _;
    }
    event GameStarted(uint256 gameIndex, uint256 startTime);
    event WinnerGetRewards(uint256 gameIndex, address winner, uint256 amount);
    event GameParamChanged(
        uint256 bidEndTime,
        uint256 maxBidInterval,
        uint256 commission
    );
    event Bid(
        uint256 ganeIndex,
        address bidder,
        uint256 bidAmount,
        uint256 bidTime
    );
    event PaymentReceived(address from, uint256 amount);

    function checkGameRunning() public view returns (bool) {
        uint256 currentTime = block.timestamp;
        if (
            startBidding &&
            currentTime < startTime.add(bidEndTime) &&
            (curBidAmount ==0  || currentTime > curBidTime.add(maxBidInterval))
        ) return true;
        else return false;
    }

    function start() public onlyOwner gameEnded {
        //
        startTime = block.timestamp;
        curBidTime = startTime;
        curBidAmount = 0;
        startBidding = true;
        lastBidder = address(0);
        gameIndex = gameIndex + 1;
        totalWinnerAmount = 0;
        emit GameStarted(gameIndex, startTime);
    }

    function rewardToWinner() public onlyOwner gameEnded {
        payable(lastBidder).transfer(totalWinnerAmount);
        emit WinnerGetRewards(gameIndex, lastBidder, totalWinnerAmount);
        start();
    }

    function setGameParams(
        uint256 _bidEndTime,
        uint256 _maxBidInterval,
        uint256 _commission
    ) public onlyOwner {
        require(_commission < 1000, "commission overflow");
        bidEndTime = _bidEndTime;
        maxBidInterval = _maxBidInterval;
        commission = _commission;
        emit GameParamChanged(bidEndTime, maxBidInterval, commission);
    }

    function bid() external payable gameRunning {
        require(msg.value > curBidAmount, "bid amount is less than before");
        lastBidder = msg.sender;
        // send commistion to owner
        uint256 commissionAmount = msg.value.mul(commission).div(1000);
        _totalCommissionAmount = _totalCommissionAmount.add(commissionAmount);
        curBidTime = block.timestamp;
        curBidAmount = msg.value;
        totalWinnerAmount = totalWinnerAmount.add(msg.value).sub(
            commissionAmount
        );
        emit Bid(gameIndex, lastBidder, msg.value, curBidTime);
    }

    function withdraw(address toAddress) public onlyOwner {
        payable(toAddress).transfer(_totalCommissionAmount);
        _totalCommissionAmount = 0;
    }

    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }
}
