// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PricePredictionGame {
    address private manager;
    address private gameToken;
    AggregatorV3Interface private priceFeed;

    struct Bet {
        uint256 amount;
        bool isUp;
        bool isSettled;
    }

    struct Slot {
        uint256 startTime;
        uint256 endTime;
        mapping(address => Bet) bets;
    }

    Slot private activeSlot;
    uint256 private slotDuration = 5 minutes;
    uint256 private poolAmount;

    event BetPlaced(address indexed player, uint256 amount, bool isUp);
    event SlotFinalized(bool isUpWins, uint256 poolAmount);

    constructor(address _gameToken, address _priceFeed) {
        manager = msg.sender;
        gameToken = _gameToken;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }

    function placeBet(bool _isUp) external payable {
        require(msg.value > 0, "Bet amount must be greater than 0");
        require(activeSlot.endTime > block.timestamp, "Betting for this slot has closed");

        Bet storage bet = activeSlot.bets[msg.sender];
        require(!bet.isSettled, "Cannot place multiple bets in the same slot");

        bet.amount = msg.value;
        bet.isUp = _isUp;
        bet.isSettled = false;
        
        poolAmount += msg.value;

        emit BetPlaced(msg.sender, msg.value, _isUp);
    }

    function initializeNextSlot() external onlyManager {
        require(activeSlot.endTime == 0 || block.timestamp >= activeSlot.endTime, "Cannot initialize a new slot yet");

        activeSlot.startTime = block.timestamp;
        activeSlot.endTime = block.timestamp + slotDuration;
    }

function finalizeSlot() external onlyManager {
    require(block.timestamp >= activeSlot.endTime, "Slot not yet completed");

    (uint80 roundID, int256 price, , , ) = priceFeed.latestRoundData();
    bool isUpWins = (price > 0);

    address[] memory bettors = new address[](poolAmount); // Array to store betting addresses
    uint256 index = 0;

    // Collect all betting addresses into the array
    for (uint256 i = 0; i < poolAmount; i++) {
        address player = address(0);
        bool found = false;
        // Iterate over the mapping to find the betting addresses
        for (uint256 j = 0; j < poolAmount; j++) {
            if (!activeSlot.bets[bettors[j]].isSettled && index == j) {
                player = bettors[j];
                found = true;
                break;
            }
        }

        // If a betting address is found, add it to the array
        if (found) {
            bettors[index] = player;
            index++;
        } else {
            break; // All betting addresses have been collected, exit the loop
        }
    }

    for (uint256 i = 0; i < index; i++) {
        address player = bettors[i];
        Bet storage bet = activeSlot.bets[player];

        if ((bet.isUp && isUpWins) || (!bet.isUp && !isUpWins)) {
            IERC20(gameToken).transfer(player, bet.amount);
        }

        bet.isSettled = true;
    }

    emit SlotFinalized(isUpWins, poolAmount);

    poolAmount = 0;
    }
}