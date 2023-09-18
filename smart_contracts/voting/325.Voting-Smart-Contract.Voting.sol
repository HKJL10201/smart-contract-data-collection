// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Voting {
    using SafeMath for uint256;

    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    // Store accounts that have voted
    mapping(address => bool) public voters;

    // Store Candidates
    mapping(uint256 => Candidate) public candidates;
    // Store Candidates Count
    uint256 public candidatesCount;

    // voted event
    event votedEvent(uint256 indexed _candidateId);

    // Candidate Constructor
    constructor() {
        addCandidate("Aashish");
        addCandidate("Person 2");
        addCandidate("This guy");
    }

    // Add Candidate
    function addCandidate(string memory _name) private {
        candidatesCount = candidatesCount.add(1);
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    // Vote
    function vote(uint256 _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender], "Voter has already voted");

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount = candidates[_candidateId].voteCount.add(1);

        // trigger voted event
        emit votedEvent(_candidateId);
    }

    uint256 public winningCandidateId;
    function determineWinner() public view returns (uint256, string memory) {
    uint256 maxVotes = 0;
    uint256 currentWinningCandidateId = 0;
    bool isTie = true;
    for (uint256 i = 1; i <= candidatesCount; i++) {
        if (candidates[i].voteCount > maxVotes) {
            maxVotes = candidates[i].voteCount;
            currentWinningCandidateId = candidates[i].id;
            isTie = false;
        }
        else if (candidates[i].voteCount == maxVotes) {
            isTie = true;
        }
    }
    if (isTie) {
        return (0, "Tie");
    } else {
        return (currentWinningCandidateId, candidates[currentWinningCandidateId].name);
    }
}


    function endVoting() public {
    (uint256 id, string memory winningCandidateName) = determineWinner();
    winningCandidateId = id;
    emit winnerEvent(winningCandidateId, winningCandidateName);
    }

    event winnerEvent(uint256 indexed _candidateId, string _name);

}
