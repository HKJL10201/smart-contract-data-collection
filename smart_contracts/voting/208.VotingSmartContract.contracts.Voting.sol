pragma solidity ^0.8.0;

contract VotingSystem {

    struct Candidate {
        string matricule;
        uint voteCount;
    }

    mapping(address => bool) public participants;
    mapping(address => bool) public candidates;
    mapping(address => bool) public hasVoted;
    mapping(address => Candidate) public candidateInfo;
    address[] public candidateList;

    function registerParticipant() public {
        participants[msg.sender] = true;
    }

    function registerCandidate(string memory _matricule) public {
        require(participants[msg.sender], "You must be a registered participant to register as a candidate.");
        candidates[msg.sender] = true;
        candidateInfo[msg.sender] = Candidate({ matricule: _matricule, voteCount: 0 });
        candidateList.push(msg.sender);
    }

    function castVote(address _candidate) public {
        require(participants[msg.sender], "You must be a registered participant to cast a vote.");
        require(candidates[_candidate], "The address provided does not correspond to a registered candidate.");
        require(!hasVoted[msg.sender], "You have already cast your vote.");

        candidateInfo[_candidate].voteCount++;
        hasVoted[msg.sender] = true;
    }

    function getCandidateList() public view returns (address[] memory) {
        return candidateList;
    }

    function getCandidateInfo(address _candidate) public view returns (string memory, uint) {
        require(candidates[_candidate], "The address provided does not correspond to a registered candidate.");

        return (candidateInfo[_candidate].matricule, candidateInfo[_candidate].voteCount);
    }
}