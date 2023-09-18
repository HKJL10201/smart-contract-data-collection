pragma solidity >=0.8.0 <0.9.0;  
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

contract ethVoter is Ownable {
    bool isProposer;
    bool isVoter;
    bool hasVoted;
    vote public vote;
    uint256 public voteCountA;
    uint256 public voteCountB;
    uint256 public duration = 30 minutes;
    string public voteQuestion;
    string public voteOptionA;
    string public voteOptionB;
    struct vote {
        string voteQuestion;
        string voteOptionA;
        string voteOptionB;
        uint256 voteCountA;
        uint256 voteCountB;
        uint256 duration;
    }
    constructor () {
        vote(voteQuestion, voteOptionA, voteOptionB, voteCountA, voteCountB, duration)
    }
    modifier onlyProposer() {
        require(isProposer == true, "You are not a proposer");
        _;
    }
    modifier oneVote() {
        require(hasVoted == false, "You have already voted");
        _;
    }
    type[] queue;
    event newProposer(address proposer);
    event newVoter(address voter);
    event newVote(string voteQuestion, string voteOptionA, string voteOptionB);
    function setVoteQuestion(string memory _voteQuestion) public onlyProposer {
        voteQuestion = _voteQuestion;
    }
    function setVoteOptionA(string memory _voteOptionA) public onlyProposer {
        voteOptionA = _voteOptionA;
    }
    function setVoteOptionB(string memory _voteOptionB) public onlyProposer {
        voteOptionB = _voteOptionB;
    }
    function setProposer() private onlyOwner {
        isProposer = true;
    }
    function setVoter() private onlyOwner {
        isVoter = true;
    }
    function voteA() public oneVote {
        require(isVoter == true, "You are not a voter");
        require(hasVoted == false, "You have already voted");
        voteCountA++;
        hasVoted = true;
    }
    function voteB() public oneVote {
        require(isVoter == true, "You are not a voter");
        require(hasVoted == false, "You have already voted");
        voteCountB++;
        hasVoted = true;
    }
    function getVoteCountA() public view returns (uint256) {
        return voteCountA;
    }
    function getVoteCountB() public view returns (uint256) {
        return voteCountB;
    }
    function payToBeProposer() public payable {
        require(msg.value == 0.02 ether, "You must pay 0.2 ether to be a proposer");
        setProposer();
    }
    function payToBeVoter() public payable {
        require(msg.value == 0.01 ether, "You must pay 0.1 ether to be a voter");
        setVoter();
    }
    function setDuration(uint256 _duration) public onlyProposer {
        duration = _duration;
    }
    function proposeVote() public onlyProposer {
        queue.push(vote(voteQuestion, voteOptionA, voteOptionB, voteCountA, voteCountB, duration));
    }
    function nextVote() public {
        require(queue.length > 0, "There are no votes to be voted on");
        if (queue[0].duration > 0, "The vote has not expired yet") {
            return;
        }
        else {
            queue.shift();
        }
    }
    function decideWinner() public {
        require(queue.length > 0, "There are no votes to be voted on");
        if (queue[0].voteCountA > queue[0].voteCountB) {
            return queue[0].voteOptionA;
        }
        else {
            return queue[0].voteOptionB;
        }
    }
    function startVote() public {
        queue[0].duration = block.timestamp + duration;
        
    }
    function durationCountdown()
}

