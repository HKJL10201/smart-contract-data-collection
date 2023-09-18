// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Voting {

    uint public electionCount = 0;

    mapping (uint => Election) public elections;

    struct Election {
        string electionCode;
        string name;
        uint numCandidates;
        uint startDate;
        uint endDate;
        string[] candidates;
        mapping (address => uint) eligibleVoters;
        mapping (string => uint) votes;
    }

    function createElection(string memory _electionCode, string memory _name, uint _numCandidates, uint _startDate, uint _endDate, string[] memory _candidates, string[] memory _eligibleVoters) public {
        electionCount += 1;
        Election storage e = elections[electionCount];
        e.electionCode = _electionCode;
        e.name = _name;
        e.numCandidates = _numCandidates;
        e.startDate = _startDate;
        e.endDate = _endDate;
        e.candidates = _candidates;
        for (uint i=0; i<_eligibleVoters.length; i++) {
            e.eligibleVoters[address(bytes20(bytes(_eligibleVoters[i])))] = 1;
        }
    }

    function vote(uint electionId, string memory _candidate) public {
        //require(block.timestamp >= elections[electionId].startDate, "Election is not active");
       // require(block.timestamp <= elections[electionId].endDate, "Election is finished");
        //require(elections[electionId].eligibleVoters[msg.sender] == 1 || elections[electionId].eligibleVoters[msg.sender] == 2, "You are not an eligible voter");
        require(elections[electionId].eligibleVoters[msg.sender] != 2, "Already Voted");
        elections[electionId].eligibleVoters[msg.sender] = 2;
        elections[electionId].votes[_candidate] += 1;
    }

    function getCandidate(uint electionId, uint index) public view returns (string memory) {
        return elections[electionId].candidates[index];
    }

    function getVotes(uint electionId, string memory _candidate) public view returns (uint) {
        return elections[electionId].votes[_candidate];
    }

    function findWinner(uint electionId) public view returns (string memory) {
        uint maxVotes = 0;
        string memory winner;
        for (uint i=0; i<elections[electionId].numCandidates; i++) {
            if (elections[electionId].votes[elections[electionId].candidates[i]] > maxVotes) {
                winner = elections[electionId].candidates[i];
            }
        }
        return winner;
    }
}