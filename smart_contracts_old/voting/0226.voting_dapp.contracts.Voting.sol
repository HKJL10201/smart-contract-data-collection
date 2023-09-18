// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

// Create a dapp for voting where all of the votes and candidate registration happens on chain.
// Allow anyone to start an election with a registration period, voting period, and ending time.
// Allow anyone to sign up as a candidate during the registration period, and allow anyone to vote once during the voting period.
// Create a front end where voters can see the results and know how long is left in the election.

contract Voting {
    struct Vote {
        address voterAddress;
        address candidateKey;
    }
    mapping(address => Vote) public votes;
    mapping(address => mapping(bytes32 => bool)) public hasVotedInElectionMapping;

    struct Candidate {
        uint candidateListPointer;
        bytes32 name;
        uint256 voteCount;
        address candidateAddress;
        bytes32 electionKey;
        address[] votes;
    }
    mapping(address => Candidate) public candidates;
    address[] public candidateList;

    struct Election {
        uint electionListPointer;
        bytes32 name;
        string proposal;
        uint registrationDeadline; // In seconds
        uint votingDeadline; // In seconds
        uint endingTime; // In seconds
        address[] candidates;
    }
    mapping(bytes32 => Election) public elections;
    mapping(bytes32 => mapping(address => uint)) public candidateListPointers;
    bytes32[] public electionList;

    event ElectionCreated(address creator, bytes32 electionName);
    event CandidateRegistered(bytes32 candidateName, bytes32 electionName);
    event CandidateDeleted(bytes32 candidateName, bytes32 electionName);
    event VoteRegistered(address voter, bytes32 electionName);

    function createElection(
        bytes32 electionName,
        string memory proposal,
        uint registrationDeadline,
        uint votingDeadline,
        uint endingTime
        ) public returns(bool success)
    {
        require(!isElection(electionName), "Election with that name already exists.");

        electionList.push(electionName);

        Election storage e = elections[electionName];

        e.electionListPointer = electionList.length - 1;
        e.name = electionName;
        e.proposal = proposal;
        e.registrationDeadline = block.timestamp + registrationDeadline;
        e.votingDeadline = block.timestamp + votingDeadline;
        e.endingTime = block.timestamp + endingTime;

        emit ElectionCreated(msg.sender, electionName);

        return true;
    }

    function getNumberOfElections() public view returns(uint) {
        return electionList.length;
    }

    function isElection(bytes32 electionName) public view returns (bool isIndeed) {
        if(electionList.length == 0) return false;
        return electionList[elections[electionName].electionListPointer] == electionName;
    }

    function registerCandidate(bytes32 electionName, bytes32 candidateName) public returns (bool success) {
        require(isElection(electionName), "No election with that name found.");
        require(block.timestamp < elections[electionName].registrationDeadline, "Registration period has ended.");
        require(!isCandidate(msg.sender), "You have already registered for an election.");

        candidateList.push(msg.sender);

        Candidate storage c = candidates[msg.sender];

        c.candidateListPointer = candidateList.length - 1;
        c.name = candidateName;
        c.voteCount = 0;
        c.candidateAddress = msg.sender;
        c.electionKey = electionName;

        elections[electionName].candidates.push(msg.sender);
        candidateListPointers[electionName][msg.sender] = elections[electionName].candidates.length - 1;

        emit CandidateRegistered(candidateName, electionName);

        return true;
    }

    function getNumberOfCandidates() public view returns(uint) {
        return candidateList.length;
    }

    function isCandidate(address candidateAddress) public view returns (bool isIndeed) {
        if(candidateList.length == 0) return false;
        return candidateList[candidates[candidateAddress].candidateListPointer] == candidateAddress;
    }

    function deleteCandidate(address candidateAddress) public returns (bool success) {
        require(isCandidate(candidateAddress), "Candidate not found.");
        require(msg.sender == candidateAddress, "Only candidate himself/herself can withdraw from election.");

        // Replace candidate to delete with last element of array; remove last element; change pointer to list of candidates
        uint rowToDelete = candidates[candidateAddress].candidateListPointer;
        address keyToMove = candidateList[candidateList.length - 1];
        candidateList[rowToDelete] = keyToMove;
        candidates[candidateAddress].candidateListPointer = rowToDelete;
        bytes32 candidateName = candidates[candidateAddress].name; // Store name before deleting candidate to emit event
        candidateList.pop();

        // Delete candidate reference from associated election; fetch election from candidate; apply same deletion steps as previously
        bytes32 electionName = candidates[candidateAddress].electionKey;
        rowToDelete = candidateListPointers[electionName][candidateAddress];
        keyToMove = elections[electionName].candidates[elections[electionName].candidates.length - 1];
        elections[electionName].candidates[rowToDelete] = keyToMove;
        candidateListPointers[electionName][keyToMove] = rowToDelete;
        elections[electionName].candidates.pop();

        emit CandidateDeleted(candidateName, electionName);

        return true;
    }

    function vote(bytes32 electionName, address candidateAddress) public returns (bool success) {
        require(isElection(electionName), "No election with that name found.");
        require(!hasVoted(electionName), "Your vote was already registered in that election.");
        require(msg.sender != candidateAddress, "You can't simply vote for yourself!");

        require(block.timestamp < elections[electionName].endingTime, "Election has already ended.");
        require(block.timestamp < elections[electionName].votingDeadline, "Voting period is over.");
        require(block.timestamp < elections[electionName].registrationDeadline, "Candidates are still registering.");

        Vote storage v = votes[msg.sender];

        v.voterAddress = msg.sender;
        v.candidateKey = candidateAddress;

        hasVotedInElectionMapping[msg.sender][electionName] = true;

        candidates[candidateAddress].votes.push(msg.sender);
        candidates[candidateAddress].voteCount++;

        emit VoteRegistered(msg.sender, electionName);

        return true;
    }

    function hasVoted(bytes32 electionName) public view returns (bool hasIndeed) {
        return hasVotedInElectionMapping[msg.sender][electionName];
    }
}
