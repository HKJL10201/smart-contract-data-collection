pragma solidity >=0.4.21 <0.7.0;

contract Ballot {
    struct Voter {
        uint[] voted;
        bool registerd;
        uint vote;
    }

    struct Proposal {
        bytes32 title;
        bytes32[] candidates;
        uint[] votes;
        //bytes32[] metaFeilds;
        mapping (address => Voter) voters;
        //mapping (address => address) registeredVoters;
        address[] votersAddress;
        address admin;
    }

    Proposal[] public proposals;

    function createProposal(bytes32 title) public returns (bool) {
        Proposal memory proposal;
        proposal.admin = msg.sender;
        proposal.title = title;
        proposals.push(proposal);
        return true;
    }

    function getAdmin(uint proposalIndex) public view returns (address) {
        if (proposals.length > 0) {
            if (proposals[proposalIndex].admin != address(0)) {
                return proposals[proposalIndex].admin;
            }
        }
    }

    function addCandidates(uint proposalIndex, bytes32 candidate) public returns (bool){
        if (proposals.length > 0) {
            if (msg.sender == proposals[proposalIndex].admin) {
                proposals[proposalIndex].candidates.push(candidate);
                proposals[proposalIndex].votes.push(0);
            }
        }
    }

    function getCandidates(uint proposalIndex, uint candidateIndex) public view returns (bytes32 candidateName) {
        if (proposals.length > 0) {
            Proposal memory p = proposals[proposalIndex];
            return (p.candidates[candidateIndex]);
        }
    }

    function getNumberOfCandidates(uint proposalIndex) public view returns (uint) {
        if (proposals.length > 0) {
            return proposals[proposalIndex].candidates.length;
        }
    }

    function getNumberOfProposals() public view returns (uint) {
        return proposals.length;
    }

    function getProposal(uint proposalIndex) public view returns (bytes32 title) {
        if (proposals.length > 0) {
            Proposal memory p = proposals[proposalIndex];
            return (p.title);
        }
    }

    function getVoteTally(uint proposalIndex, uint candidateIndex) public view returns (uint) {
        if (proposals.length > 0) {
            Proposal memory p = proposals[proposalIndex];
            if (candidateIndex < p.votes.length) {
                return (p.votes[candidateIndex]);
            }
        }
    }

    

    function votedAlready(uint proposalIndex, uint candidateIndex) public view returns (bool) {
        if (proposals.length > 0) {
            if (candidateIndex < proposals[proposalIndex].votes.length) {
                Voter memory v = proposals[proposalIndex].voters[msg.sender];
                for (uint i = 0; i < v.voted.length; i++) {
                    if (v.voted[i] == candidateIndex) { 
                        return true;
                    }
                }
                return false;
            }
            
        }
    }

    function vote(uint proposalIndex, uint candidateIndex, uint rating) public returns (bool) {
        if (proposals.length > 0) {
            if (candidateIndex < proposals[proposalIndex].votes.length) {
                Voter memory v = proposals[proposalIndex].voters[msg.sender];
                for (uint i = 0; i < v.voted.length; i++) {
                    if (v.voted[i] == candidateIndex) { 
                        return false;
                    }
                }
                proposals[proposalIndex].voters[msg.sender].voted.push(candidateIndex);
                proposals[proposalIndex].votes[candidateIndex] += rating;
                return true;
            }
            
        }
    }
}
