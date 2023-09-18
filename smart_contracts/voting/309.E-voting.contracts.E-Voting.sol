// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.8.0;

contract Election {
    struct Ballot {
        uint32 ballotId;
        mapping(uint32 => bytes32) candidateBallot;
    }
    
    struct Candidate {
        uint32 candidateId;
        string candidateName;
        string candidateParty;
        uint256 votesReceived;
    }

    struct Voter {
        address voterAddress;
        uint32 voterId;
        bool hasVoted;
    }

    address private owner;
    modifier isOwner {
        require(msg.sender == owner, "You are not the owner of the Election!");
        _;
    }

    mapping (uint32 => Candidate) public candidates;
    mapping (address => Voter) public voters;
    uint32 public candidatesCount;
    uint32 public votersCount;
    
    event OwnerSet(address indexed newOwner);
    event AddCandidate(uint candidateId);
    event VoteInElection(uint256 indexed candidateId);
    event AnnounceElectionResults(uint256 winnerId, uint256 winnerVotes);
    
    constructor() {
        owner = msg.sender;
        emit OwnerSet(owner);
        addCandidate("Donald Trump", "Republicans");
        addCandidate("Joe Biden", "Democrats");
    }

    function resetElectionState() private {
        candidatesCount = 0;
        votersCount = 0;
    }
    
    function getNumberOfCandidates() external view returns(uint32) {
        return candidatesCount;
    }
    
    function getVotersCount() external view returns(uint32) {
        return votersCount;
    }
    
    function getCandidate(uint32 candidateId) public view returns(uint256, string memory, string memory, uint256) {
        return (candidateId, candidates[candidateId].candidateName, candidates[candidateId].candidateParty, candidates[candidateId].votesReceived);
    }

    function getTotalVotes(uint32 candidateId) view public returns (uint256) {
        require(candidateId > 0, "Invalid candidate ID");
        return candidates[candidateId].votesReceived;
    }
    
    function addCandidate(string memory name, string memory party) isOwner public {
        require(checkForUniqueCandidate(name), "Candidate already exists");
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, name, party, 0);
        emit AddCandidate(candidatesCount);
    }

    function checkForUniqueCandidate(string memory name) view private returns (bool){
        for(uint32 i = 0; i < candidatesCount; i++) {
            if(keccak256(abi.encodePacked(candidates[i].candidateName)) == keccak256(abi.encodePacked(name))) {
                return false;
            }
        }
        return true;
    }
    
    function vote(uint32 candidateId) public {
        // require(!voters[msg.sender], "Candidate has already voted!");
        require(candidateId > 0 && candidateId <= candidatesCount && !voters[msg.sender].hasVoted
            , "Invalid Candidate!");

        uint32 voterId = votersCount++;
        candidates[candidateId].votesReceived++;
        voters[msg.sender] = Voter(msg.sender, voterId, true);
        emit VoteInElection(candidateId);
    }

    function concludeElection() isOwner public{
        require(candidatesCount > 1, "Cannot conclude election with one candidate!");
    
        uint32 winnerId = 0;
        uint256 winnerVotesReceived = 0;

        for(uint32 i = 1; i <= candidatesCount; i++) {
            uint256 temp = getTotalVotes(candidates[i].candidateId);
            if(temp > winnerVotesReceived) {
                winnerId = candidates[i].candidateId;
                winnerVotesReceived = temp;
            }
        }

        emit AnnounceElectionResults(winnerId, winnerVotesReceived);
        resetElectionState();
    }
}