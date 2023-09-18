// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;



contract Voting {
// Define an Appropriate Data Type to Store Candidates
    struct Candidate{
        string name;
        string party;
        uint voteCount;
    }

    
    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;

    uint public candidateCount;

// Adds New Candidate
    constructor () {
        candidateCount = 0;
    }
function addCandidate(string memory _name, string memory _party ) public{
        candidateCount++;
        candidates[candidateCount] = Candidate(_name, _party, 0);
    }

// Removes Already Added Candidate
     function deleteCandidate(uint _candidateId) public {
        require(_candidateId > 0 && _candidateId <= candidateCount, "Invalid candidate ID");
        candidateCount= candidateCount-1;
        delete candidates[_candidateId];
        
    }
    

// Retrieves All Candidates for Viewing
    function getCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory allCandidates = new Candidate[](candidateCount);
        for (uint i = 1; i <= candidateCount; i++) {
            allCandidates[i - 1] = candidates[i];
        }
        return allCandidates;
    }
    

// Allows Voter to Cast a Vote for a Single Candidate
     function vote(uint candidateID) public {
        require(candidateID > 0 && candidateID <= candidateCount, "Invalid candidate ID");
        require(!voters[msg.sender], "You have already voted");

        candidates[candidateID].voteCount++;
        voters[msg.sender] = true;
     }}