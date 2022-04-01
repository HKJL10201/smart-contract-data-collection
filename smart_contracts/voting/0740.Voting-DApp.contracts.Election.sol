// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Election {

    Candidate[] public candidates;

    mapping (uint => uint) public votes;

    struct Candidate {
        uint id;
        string name;
    }
    
    uint public currId = 0;

    function addCandidate(string memory _candidate) public {
        currId++;
        candidates.push(Candidate(currId, _candidate));
        votes[currId] = 0;
    }

    function getCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    function getVotes(uint _candId) public view returns (uint) {
        require(_candId > 0 && _candId <= candidates.length);
        return votes[_candId];
    }

    // Find a less gas-intensive way of computing this. Maybe keep a variable?
    function currentLeader() public view returns (string memory) {
        uint max = 0;
        uint maxInd = 0;
        for (uint i = 1; i <= candidates.length; i++) {
            if (getVotes(i) >= max) {
                maxInd = i;
            }
        }
        return candidates[maxInd - 1].name;
    }
    
    function checkWinner(uint _candId) public view returns (bool) {
        return (votes[_candId] == 10);
    }
}