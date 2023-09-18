// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Voting contract for village chief election.
contract Voting 
{
    // Struct of a Candidate.
    struct Candidate 
    {
        uint256 id;
        string name;
        uint256 voteCount;
    }
    
    // Key - value mapping of Candidate: id - Candidate.
    mapping(uint256 => Candidate) public candidatesMap;
    // Count of candidates. It is represented as id.
    uint256 public count = 0;
    
    // Key - value mapping of votersMap: Voter address - hasVoted.
    mapping(address => bool) public votersMap;
    // Key - value mapping of votersMap: Voter address - ID.
    mapping(address => uint256) public votersMapID;

    // voted event
    event votingEvent(uint256 indexed candidateId);

    constructor() 
    {
        addCandidate("Murat Muratoglu");
        addCandidate("Ipek Koza");
        addCandidate("Ekin Yildizhan");
        addCandidate("Hilal Sari");
    }

    // Creates candidate with given name.
    function addCandidate(string memory candidateName) private 
    {
        count++;
        // Candidate is created with count id, candidateName name and 0 vote.
        candidatesMap[count] = Candidate(count, candidateName, 0);
    }

    function vote(uint256 candidateId) public 
    {
        // Voters can't vote twice, this line of code ensures that.
        assert(votersMap[msg.sender] == false);
        // Same voter can't vote for the same candidate.
        assert(votersMapID[msg.sender] == 0);
        // require a valid candidate
        assert(candidateId > 0 && candidateId <= count);

        // Voter has voted.
        votersMap[msg.sender] = true;
        // Voters candidate id is set.
        votersMapID[msg.sender] = candidateId;

        // update candidate vote Count
        candidatesMap[candidateId].voteCount++;

        emit votingEvent(candidateId);
    }
}