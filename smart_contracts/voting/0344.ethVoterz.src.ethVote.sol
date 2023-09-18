pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract EthVote is Ownable {
    bool public isProposer;
    bool public isVoter;
    bool public hasVoted;
    uint256 public duration = 30 minutes;
    string public voteQuestion;
    string public voteOptionA;
    string public voteOptionB;
    uint256 public voteCountA;
    uint256 public voteCountB;
    struct Vote {
        string voteQuestion;
        string voteOptionA;
        string voteOptionB;
        uint256 voteCountA;
        uint256 voteCountB;
        uint256 duration;
        bool isActive;
        uint256 voteStartTime;
    }
    Vote[] public votes;
    event NewProposer(address proposer);
    event NewVoter(address voter);
    event NewVote(uint256 voteId, string voteQuestion, string voteOptionA, string voteOptionB);
    event VoteCast(uint256 voteId, bool voteOption);
    event VoteStarted(string voteQuestion, string voteOptionA, string voteOptionB, uint256 duration);
    event VoteEnded(string voteQuestion, string voteOptionA, string voteOptionB, uint256 duration, uint256 voteCountA, uint256 voteCountB, uint256 winningOption);
    
    modifier onlyProposer() {
        require(isProposer == true, "You are not a proposer");
        _;
    }
    
    modifier onlyVoter() {
        require(isVoter == true, "You are not a voter");
        _;
    }
    
    modifier notVoted() {
        require(hasVoted == false, "You have already voted");
        _;
    }
    
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
        emit NewProposer(msg.sender);
    }
    
    function setVoter() private onlyOwner {
        isVoter = true;
        emit NewVoter(msg.sender);
    }

    function vote(uint256 _voteId, bool _voteOption) public onlyVoter notVoted {
        Vote storage voted = votes[_voteId];
        require(voted.isActive == true, "The vote is not active");
        
        if (_voteOption) {
            voted.voteCountA++;
            emit VoteCast(_voteId, true);
        } else {
            voted.voteCountB++;
            emit VoteCast(_voteId, false);
        }
        hasVoted = true;
    }

    function createVote() public onlyProposer {
        Vote memory newVote = Vote({
            voteQuestion: voteQuestion,
            voteOptionA: voteOptionA,
            voteOptionB: voteOptionB,
            voteCountA: 0,
            voteCountB: 0,
            duration: duration,
            isActive: true,
            voteStartTime: block.timestamp
        });
        votes.push(newVote);
        emit NewVote(votes.length - 1, voteQuestion, voteOptionA, voteOptionB);
    }

    function endVote() public onlyOwner {
        require(votes.length > 0, "No vote is currently open");

        Vote storage currentVote = votes[votes.length - 1];
        require(currentVote.isActive, "The vote is not active");

        uint256 timeElapsed = block.timestamp - currentVote.voteStartTime;
        require(timeElapsed >= currentVote.duration, "Vote duration has not ended");

        currentVote.isActive = false;
        uint256 winningOption;
        if (currentVote.voteCountA > currentVote.voteCountB) {
            winningOption = 1;
        } else if (currentVote.voteCountB > currentVote.voteCountA) {
            winningOption = 2;
        }
        emit VoteEnded(
            currentVote.voteQuestion, 
            currentVote.voteOptionA, 
            currentVote.voteOptionB, 
            currentVote.duration, 
            currentVote.voteCountA, 
            currentVote.voteCountB, 
            winningOption
        );

        // Start the next vote in the queue
        if (votes.length > 1) {
            Vote storage nextVote = votes[1];
            voteQuestion = nextVote.voteQuestion;
            voteOptionA = nextVote.voteOptionA;
            voteOptionB = nextVote.voteOptionB;
            duration = nextVote.duration;
            nextVote.voteCountA = 0;
            nextVote.voteCountB = 0;
            Vote memory newVote = Vote({
                voteQuestion: voteQuestion,
                voteOptionA: voteOptionA,
                voteOptionB: voteOptionB,
                voteCountA: 0,
                voteCountB: 0,
                duration: duration,
                isActive: true,
                voteStartTime: block.timestamp
            });
            votes.push(newVote);
            emit NewVote(votes.length - 1, voteQuestion, voteOptionA, voteOptionB);
        }
        votes.pop();
        startVote();
    }
    function startVote() public onlyOwner {
        require(votes.length > 0, "No vote is currently open");
        Vote storage currentVote = votes[votes.length - 1];
        require(currentVote.isActive, "The vote is not active");
        emit VoteStarted(
            currentVote.voteQuestion, 
            currentVote.voteOptionA, 
            currentVote.voteOptionB, 
            currentVote.duration
        );
    }
    function payToBeProposer() public payable {
        require(msg.value == 0.02 ether, "You must pay 0.2 ether to be a proposer");
        setProposer();
    }

    function payToBeVoter() public payable {
        require(msg.value == 0.01 ether, "You must pay 0.1 ether to be a voter");
        setVoter();
    }

} 

