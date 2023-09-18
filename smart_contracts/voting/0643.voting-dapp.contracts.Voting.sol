//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
contract Voting { 
    
    using Counters for Counters.Counter;
 
    Counters.Counter public _electionCounter;

    struct Election {
        string electionName;
        uint electionStart;
        uint registrationPeriod;
        uint votingPeriod;
        uint endingTime;
    }

    struct Candidate {
        string name;
        string surname;
    }

    mapping(address => mapping(uint => bool))  public candidateInElection;
    mapping(uint => address[]) public electionCandidates;
    mapping(address => bool) candidateExists;
    mapping(address => mapping(uint => uint)) candidateVotes;
    mapping(address => mapping(uint => bool)) voter;
    mapping(uint =>  Counters.Counter) public candidatesInElectionCount;
    
 

    mapping(uint => Election) public elections;
    mapping(address => Candidate) public candidates;
    mapping(uint => bool) electionExists;

    event ElectionAdded(uint electionId);
    event CandidateAdded(address candidateAddress, uint electionId);
    event VotedForCandidate(address voter, address candidate, uint electionId);
    event SignedAsCandidate(address candidate);
    constructor() {
       
    }

    modifier candidateSignedUp(address addressToCheck, bool needItSignedUp) {
        if(needItSignedUp){
             require(candidateExists[addressToCheck], "Sign up as a candidate first!");
        }else{
             require(!candidateExists[addressToCheck], "You can just register once!");
            
        }
       
        _;
    }

    function signUpAsCandidate(string memory name, string memory surname) public candidateSignedUp(msg.sender, false){
        candidateExists[msg.sender] = true;
        candidates[msg.sender] = Candidate(name, surname);
        emit SignedAsCandidate(msg.sender);
    }
    function candidateIsInElection(address candidateAddress, uint electionId) public view returns(bool) {
        return candidateInElection[candidateAddress][electionId];
    }
    function startElection(string memory electionName, uint registrationPeriod, uint votingPeriod, uint endingTime) public {
        elections[_electionCounter.current()] =  Election(electionName, block.timestamp,registrationPeriod, votingPeriod, endingTime);
        electionExists[_electionCounter.current()] = true;
        emit ElectionAdded(_electionCounter.current());
        _electionCounter.increment();
        
    }
    
    function registerToElection(uint electionId) public candidateSignedUp(msg.sender, true){
        require(electionExists[electionId], "Election doesn't exist!");
        require(block.timestamp < (elections[electionId].electionStart + elections[electionId].registrationPeriod) , "The registration period for this election is closed!");
        require(!candidateInElection[msg.sender][electionId], "Candidate already registered for this election!");
        candidateInElection[msg.sender][electionId] = true;
        electionCandidates[electionId].push(msg.sender);
        emit CandidateAdded(msg.sender, electionId);
    }

    function voteForCandidate(address candidateAddress, uint electionId) public candidateSignedUp(candidateAddress, true){
        require(block.timestamp < ((elections[electionId].electionStart + elections[electionId].registrationPeriod)+ elections[electionId].votingPeriod), "The voting period for this election is closed!");
        require(!voter[msg.sender][electionId], "You already voted for this election!");
        require(candidateInElection[candidateAddress][electionId], "This candidate is not registered for this election!");
        candidateVotes[candidateAddress][electionId]++;
        voter[msg.sender][electionId] = true;
        emit VotedForCandidate(msg.sender, candidateAddress, electionId);
    }
    function getCandidateVotes(address candidateAddress, uint electionId) public view returns(uint){
        return candidateVotes[candidateAddress][electionId];
    }
    function getCandidatesInElection(uint electionId) public view returns(address[] memory){
        return electionCandidates[electionId];
    }
    
}
