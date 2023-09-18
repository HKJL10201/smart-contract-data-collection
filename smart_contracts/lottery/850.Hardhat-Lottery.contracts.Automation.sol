// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "./LotteryInterface.sol";

error Automation__PerformUpkeepFailed();
error Automation__InvalidData();

contract Automation is AutomationCompatibleInterface {
    LotteryInterface public lottery;

    event UpkeepPerformed(bytes performData);

    constructor(address _lottery) {
        lottery = LotteryInterface(_lottery);
    }

    function checkUpkeep(
        bytes calldata checkData
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        if (keccak256(checkData) == keccak256(bytes(abi.encode("request")))) {
            bool isInterval = (block.timestamp - lottery.getLatestCheckpoint() >=
                lottery.getInterval() * 10);
            bool isParticipated = (lottery.getPlayerCounter() > 1);
            bool isOpen = lottery.getState();
            upkeepNeeded = (isInterval && isParticipated && isOpen);
            performData = checkData;
        }
        if (keccak256(checkData) == keccak256(bytes(abi.encode("pick")))) {
            bool isInterval = (block.timestamp - lottery.getLatestCheckpoint() >=
                lottery.getInterval());
            bool isRandom = (lottery.getRandomNumber() != 0);
            bool isClosed = !lottery.getState();
            upkeepNeeded = (isInterval && isRandom && isClosed);
            performData = checkData;
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        if (keccak256(performData) == keccak256(bytes(abi.encode("request")))) {
            if (
                (block.timestamp - lottery.getLatestCheckpoint() >= lottery.getInterval() * 10) &&
                (lottery.getPlayerCounter() > 1) &&
                (lottery.getState())
            ) {
                lottery.requestRandomWinner();
            } else {
                revert Automation__PerformUpkeepFailed();
            }
        } else if (keccak256(performData) == keccak256(bytes(abi.encode("pick")))) {
            if (
                (block.timestamp - lottery.getLatestCheckpoint() >= lottery.getInterval()) &&
                (lottery.getRandomNumber() != 0) &&
                (!lottery.getState())
            ) {
                lottery.pickRandomWinner();
            } else {
                revert Automation__PerformUpkeepFailed();
            }
        } else {
            revert Automation__InvalidData();
        }
        emit UpkeepPerformed(performData);
    }
}
