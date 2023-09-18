// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    string public description = "";
    uint256 public votesA = 0;
    uint256 public votesB = 0;
    uint256 pollStatus = 0;
    uint256 pollDuration = 0;
    uint256 pollStartDate = 0;

    function createPoll(string memory pollDescription, uint256 durationInDays) public onlyOwner {
        require(pollStatus == 0, "An poll is already running");
        require(durationInDays > 0, "The voting period cannot be 0.");
        description = pollDescription;
        pollStatus = 1;
        pollStartDate = block.timestamp;
        pollDuration = durationInDays;
    }

    function castVote(bool vote) public {
        require(pollStatus == 1, "No poll is running");
        require(block.timestamp < pollStartDate + (pollDuration * 1 days), "Poll has already ended");
        if(vote){
            votesA++;
        }else{
            votesB++;
        }
    }

    function resetPoll() public onlyOwner {
        description = "";
        pollStatus = 0;
        pollStartDate = 0;
        pollDuration = 0;
    }

    function getPollStatus() public view returns(string memory){
        if(pollStatus == 1){
            return "A poll is running.";
        }else{
            return "No poll is running.";
        }
    }

    function getWinner() public view returns(string memory){
        require(pollStatus == 1, "No poll is running");
        require(block.timestamp < pollStartDate + (pollDuration * 1 days), "Poll has already ended");
        if(votesA > votesB){
            return "A is winning";
        }else if(votesA == votesB){
            return "Its a tie!";
        }else{
            return "B is winning";
        }
    }

}