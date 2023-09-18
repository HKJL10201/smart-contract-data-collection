// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./VoterDeclaration.sol";
import "./ElectionDeclaration.sol";

contract VotingContract is ElectionStorage, Voters{

    address public owner;

    function getBalance() external view returns(uint){ 
        return address(this).balance;
    }

    function getNumberOfElections() public view electionExist returns (uint){ 
        return elections.length;
    }

     constructor(){ 
        owner = msg.sender; 
        // require (_candidates.length > 0, "There should be atleast 1 candidate.");
        // for (uint i = 0; i < _candidates.length; i++){ 
        //     addCandidate(_candidates[i]);
        // }
    }

    modifier onlyOwner (){ 
        require(msg.sender == owner, "you are not an owner!");
        _;
    }

    modifier electionExist{ 
        require(elections.length > 0, "Elections isn't created!");
        _;
    }

    modifier isVoter(address _voterAddress) {
		require(_voterAddress != address(0) ,"Voter with default address!");
        _;
	}

    // function getCurrentStatus() public view electionExist returns (uint) {
	// 	return elections[currentElectionId].status;
	// }

    // function getCurrentElection() public view electionExist returns (Election memory) {
	// 	return elections[currentElectionId];
	// }

    // function getAllElections() public view returns (Election[] memory) {
	// 	return elections;
	// }


    function createVoting(uint duration, p) external onlyOwner{
        require (_candidates.length > 0, "There should be atleast 1 candidate.");

        if(elections.length != 0) { currentElectionId++; }
        uint electionEnd = block.timestamp + duration * 1 hours;
        uint electionStart = block.timestamp;
       
        elections.push();
        Election storage newElection = elections[elections.length - 1];
        newElection.id = currentElectionId;
        newElection.duration = duration;
        newElection.amount = payment;
        newElection.voteFee = votingFee;
        newElection.electionStart = electionStart;
        newElection.electionEnd = electionEnd;
        for (uint i = 0; i < _candidates.length; i++){ 
            newElection.candidates.push();
            newElection.candidates[i] = Candidate(i, _candidates[i], 0);
        }
        
        //elections[elections.length - 1] = Election(currentElectionId, 0, D, X, F, candidates, electionEnd, electionStart);

        voteRecordList.push();
        VoteRecord storage newVoteRecord = voteRecordList[elections.length - 1];
        newVoteRecord.electionId = currentElectionId;
    }

     modifier checkTimeForVote(uint numberOfVoting){ 
        require(block.timestamp >= elections[numberOfVoting].electionStart && 
                block.timestamp < elections[numberOfVoting].electionEnd, 
                "Voting is closed!");
        _; 
    }

    modifier checkTimeForWithdraw(uint numberOfVoting){ 
        require(block.timestamp >= elections[numberOfVoting].electionEnd, 
                "Voting is still open!");
        _;
    }

    modifier numberOfVotings(uint voting){ 
        require(elections.length > voting,"That voting doesnt exist!" );
        _;
    }

    function voteFor(uint voting, uint _candidate) public payable checkTimeForVote(voting) numberOfVotings(voting) isVoter(msg.sender){ 
        require(msg.value >= (elections[voting].amount + elections[voting].voteFee), "You should pay more!");
        require(_candidate < elections[voting].candidates.length && _candidate >= 0, "You should vote for the real candidate.");   
        require(!voteRecordList[voting].voted[msg.sender], "Voter has already votes!" );
        // VoteRecord[] voteRecordList;
        voteRecordList[voting].voted[msg.sender] = true;
        elections[voting].candidates[_candidate].voteCount++;
    }
     receive() external payable { 
        pay();
    }
    function pay() public payable { }
    
    function getWinnerCandidate(uint numberOfVoting) public view onlyOwner checkTimeForWithdraw(numberOfVoting) returns(Candidate memory){ 
        uint maxVotes = elections[numberOfVoting].candidates[0].voteCount;
        uint winner = 0;
        bool twoWinners = false; 
        for (uint i = 1; i < elections[numberOfVoting].candidates.length; i++){ 
            if (maxVotes < elections[numberOfVoting].candidates[i].voteCount){ 
                maxVotes = elections[numberOfVoting].candidates[i].voteCount;
                winner = i;
                twoWinners = false;
            } else if (maxVotes == elections[numberOfVoting].candidates[i].voteCount){
                twoWinners = true;
            }
        }
        
        require(maxVotes != 0, "No one has voted so far!");
        require(!twoWinners, "Candidates have the same number of votes!");
        return elections[numberOfVoting].candidates[winner];
    }

    function withdrawFees(uint numberOfVoting) public onlyOwner checkTimeForWithdraw(numberOfVoting){
        Candidate memory winner = getWinnerCandidate(numberOfVoting);
        address payable _to =  payable(winner.addr);
        uint payments = (1 - elections[numberOfVoting].voteFee) * elections[numberOfVoting].amount * elections[numberOfVoting].candidates.length;
        require(address(this).balance >= payments, "Not enough ETH");
        _to.transfer(payments);
    }

    function getVoteInfo() pure public returns (string memory){ 
        string memory info = "You should pay (X + F) ETH to take a part in the Voting!";
        return info;
    }
}