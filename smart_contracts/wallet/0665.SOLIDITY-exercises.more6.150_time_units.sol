//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Countdown {

    function getTimeUnits() external view returns(uint, uint, uint, uint, uint, uint) {
        return(block.timestamp, 1 seconds, 1 minutes, 1 hours, 1 days, 1 weeks);
    }


    uint yesVote;
    uint noVote;

    uint public startTime;
    function start() external {
        startTime = block.timestamp;
    }

    function voteYes() external {
        require(block.timestamp < startTime + 20 seconds, "voting period passed, wait next year");
        yesVote++;
    }

    function voteNo() external {
        require(block.timestamp < startTime + 20 seconds, "voting period passed, wait next year");
        noVote++;
    }
    
}