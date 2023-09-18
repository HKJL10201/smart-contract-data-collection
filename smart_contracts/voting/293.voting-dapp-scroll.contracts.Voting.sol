// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error Voting__AlreadyCastedVote();
error Voting__NotAcceptingVotesAnymore();
error Voting__NotAuthorizedToEndVoting();

contract Voting {
    struct Proposal {
        address proposer;
        string proposalCid;
        uint256 forVotes;
        uint256 againstVotes;
        bool isVoting;
    }

    uint256 public proposalCounter;
    mapping(uint256 => Proposal) proposalIdToProposal;
    mapping(address => mapping(uint256 => bool)) addressToProposalIdVoted;

    function createProposal(
        string memory _proposalCid
    ) external returns (bool success) {
        Proposal memory newProposal = Proposal(
            msg.sender,
            _proposalCid,
            0,
            0,
            true
        );
        proposalCounter++;
        proposalIdToProposal[proposalCounter] = newProposal;
        success = true;
    }

    function endVoting(
        uint256 _proposalId
    ) external view returns (bool isProposalAccepted) {
        if (msg.sender != proposalIdToProposal[_proposalId].proposer) {
            revert Voting__NotAuthorizedToEndVoting();
        }
        if (
            proposalIdToProposal[_proposalId].forVotes >=
            proposalIdToProposal[_proposalId].againstVotes
        ) {
            isProposalAccepted = true;
        } else {
            isProposalAccepted = false;
        }
    }

    function castVote(
        uint256 _proposalId,
        bool forVote
    ) external returns (bool success) {
        if (!proposalIdToProposal[_proposalId].isVoting) {
            revert Voting__NotAcceptingVotesAnymore();
        }
        if (addressToProposalIdVoted[msg.sender][_proposalId]) {
            revert Voting__AlreadyCastedVote();
        }
        if (forVote) {
            proposalIdToProposal[_proposalId].forVotes++;
        } else {
            proposalIdToProposal[_proposalId].againstVotes++;
        }
        addressToProposalIdVoted[msg.sender][_proposalId] = true;
        success = true;
    }
}
