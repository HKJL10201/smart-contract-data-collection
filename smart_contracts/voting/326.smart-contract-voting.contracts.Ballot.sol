// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Ballot{


    address owner;                  // The address of the owner.
    bool    optionsFinalized;       // Whether the owner can still add voting options.
    string  ballotName;             // The ballot name.
    uint    ballotEndTime;          // End time for ballot after which no changes can be made. (seconds since 1970-01-01)

    struct Voter {
        uint id;
        bool voted;
        uint candidateIDVote;
    }

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }


    mapping(uint => Candidate) public candidateLookup; //maps candidate to a unique id
    uint public numCandidates; //counter for number of candidates

    function addCandidate(string memory name) public {
        candidateLookup[numCandidates] = Candidate(numCandidates, name, 0);
        numCandidates++; 
    }   

    constructor() {
        addCandidate("Mac"); // First candidate ID: 0
        addCandidate("Joe"); // Second candidate ID: 1
    }

    function getCandidate(uint id) external view returns (string memory name, uint voteCount) {
        name = candidateLookup[id].name;
        voteCount = candidateLookup[id].voteCount;
    }

    function getCandidates() external view returns (string[] memory, uint[] memory) {
    string[] memory names = new string[](numCandidates);
    uint[] memory voteCounts = new uint[](numCandidates);
    for (uint i = 0; i < numCandidates; i++) {
        names[i] = candidateLookup[i].name;
        voteCounts[i] = candidateLookup[i].voteCount;
    }
        return (names, voteCounts);
    }

    function getNumCandidates() public view returns(uint) {
        return numCandidates;
    }


}