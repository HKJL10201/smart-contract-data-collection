// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPriceConverter.sol";
import "./IRandomNumberGenerator.sol";

error Lottery__NotEntranceFee();
error Lottery__RandomNumberNotExists();
error Lottery__TransferFailed();
error Lottery__NotRightTime();
error Lottery__Closed();
error Lottery__Open();
error Lottery__NotEnoughParticipant();

contract Lottery is Ownable {
    uint256 private immutable entranceFee;
    uint256 private immutable interval;
    uint256 private latestCheckpoint;
    uint256 private playerCounter;
    uint256 private requestId;
    address payable private recentWinner;
    bool private isOpen = true;

    mapping(uint256 => address payable) private players;

    IPriceConverter public priceConverter;
    IRandomNumberGenerator public randomNumberGenerator;

    event LotteryEntered(address indexed player);
    event WinnerRequested(uint256 indexed requestId);
    event WinnerPicked(address indexed recentWinner);

    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _randomNumberGenerator,
        address _priceConverter
    ) {
        entranceFee = _entranceFee;
        interval = _interval;
        randomNumberGenerator = IRandomNumberGenerator(_randomNumberGenerator);
        priceConverter = IPriceConverter(_priceConverter);
        latestCheckpoint = block.timestamp;
    }

    function enterLottery() public payable {
        if (!isOpen) {
            revert Lottery__Closed();
        }
        if (
            (priceConverter.getConversionRate(msg.value) < ((entranceFee * 95) / 100)) ||
            (priceConverter.getConversionRate(msg.value) > ((entranceFee * 105) / 100))
        ) {
            revert Lottery__NotEntranceFee();
        }
        players[playerCounter] = payable(msg.sender);
        playerCounter++;
        emit LotteryEntered(msg.sender);
    }

    function requestRandomWinner() public {
        if (!isOpen) {
            revert Lottery__Closed();
        }
        if (playerCounter < 2) {
            revert Lottery__NotEnoughParticipant();
        }
        if (block.timestamp - latestCheckpoint < interval * 10) {
            revert Lottery__NotRightTime();
        }
        isOpen = false;
        latestCheckpoint = block.timestamp;
        requestId = randomNumberGenerator.requestRandomWords();
        emit WinnerRequested(requestId);
    }

    function pickRandomWinner() public {
        if (isOpen) {
            revert Lottery__Open();
        }
        if (getRandomNumber() == 0) {
            revert Lottery__RandomNumberNotExists();
        }
        if (block.timestamp - latestCheckpoint < interval) {
            revert Lottery__NotRightTime();
        }
        uint256 randomNumber = getRandomNumber();
        uint256 playerId = randomNumber % playerCounter;
        recentWinner = players[playerId];
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
        latestCheckpoint = block.timestamp;
        for (uint i = 0; i < playerCounter; i++) {
            delete players[playerId];
        }
        playerCounter = 0;
        isOpen = true;
        emit WinnerPicked(recentWinner);
    }

    function getRandomNumber() public view returns (uint256) {
        return randomNumberGenerator.getRandomNumber(requestId);
    }

    function getRequestId() public view returns (uint256) {
        return requestId;
    }

    function getEntranceFee() public view returns (uint256) {
        return entranceFee;
    }

    function getInterval() public view returns (uint256) {
        return interval;
    }

    function getLatestCheckpoint() public view returns (uint256) {
        return latestCheckpoint;
    }

    function getRecentWinner() public view returns (address) {
        return recentWinner;
    }

    function getPlayerCounter() public view returns (uint256) {
        return playerCounter;
    }

    function getPlayer(uint256 _id) public view returns (address) {
        return players[_id];
    }

    function getState() public view returns (bool) {
        return isOpen;
    }
}
