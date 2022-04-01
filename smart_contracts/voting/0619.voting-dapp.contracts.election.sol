// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./StringUtils.sol";

contract Election {
    using StringUtils for string;

    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    
    address owner;
    uint openTime;
    uint closeTime;
    
    // Store accounts that have voted
    mapping(address => bool) public voters;
    // Store Candidates
    // Fetch Candidate
    mapping(uint => Candidate) public candidates;
    // Store Candidates Count
    uint public candidatesCount;
    
    constructor() {
        owner = msg.sender;
    }

    // voted event
    event votedEvent (
        uint indexed _candidateId
    );
    
    modifier OnlyOwner() {
        require(
            owner == msg.sender,
            "Only owner can add official candidates"
        );
        _;
    }
    
    modifier OnlyWhileOpen() {
        require(
            block.timestamp >= openTime && block.timestamp <= closeTime,
            "Voting is no longer open"
        );
        _;
    }

    function setOpenAndCloseTimes(uint _openTime, uint _closeTime) public OnlyOwner {
        openTime = _openTime;
        closeTime = _closeTime;
    }

    function addOfficialCandidate (string memory _name) public OnlyOwner  {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }
    
    function voteForOfficialCandidate (uint _candidateId) public OnlyWhileOpen {
        // require that they haven't voted before
        require(
            !voters[msg.sender],
            "Multiple votes not allowed"
        );

        // require a valid candidate
        require(
            _candidateId > 0 && _candidateId <= candidatesCount,
            "The candidate id does not exist as an official candidate"
        );

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }
    
    function voteForCandidateName(string memory _name) public OnlyWhileOpen {
         // require that they haven't voted before
        require(
            !voters[msg.sender],
            "Multiple votes not allowed"
        );
            
         // record that voter has voted
        voters[msg.sender] = true;
        
        // get candidate id by name
        uint _candidateId = getCandidateIdByName(_name);
        
        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }
    
    function getCandidateIdByName(string memory _name) private returns(uint) {
        for (uint i=1; i<=candidatesCount; i++) {
            if (candidates[i].name.equal(_name)) {
                // return id of existing candidate
                return i;
            }
        }
        
        // add new candidate
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        
        // return new candidate's id
        return candidatesCount;
    }
    
}