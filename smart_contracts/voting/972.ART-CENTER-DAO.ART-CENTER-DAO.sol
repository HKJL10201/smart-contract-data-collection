// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract ArtCenterDAO {
    struct Proposal {
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public totalContributions;
    mapping(address => uint256) public balances;

    event ProposalSubmitted(uint256 proposalId, string description);
    event Voted(uint256 proposalId, bool vote, uint256 votesFor, uint256 votesAgainst);
    event ProposalExecuted(uint256 proposalId);
    event FundsWithdrawn(uint256 amount);

    function submitProposal(string memory proposalDescription) public {
        uint256 proposalId = proposalCount++;
        proposals[proposalId] = Proposal(proposalDescription, 0, 0, false);
        emit ProposalSubmitted(proposalId, proposalDescription);
    }

    function voteProposal(uint256 proposalId, bool vote) public {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");

        if (vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit Voted(proposalId, vote, proposal.votesFor, proposal.votesAgainst);
    }

    function executeProposal(uint256 proposalId) public {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.executed = true;
            emit ProposalExecuted(proposalId);

           
        }
    }

    function getProposal(uint256 proposalId) public view returns (string memory, uint256, uint256, bool) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal memory proposal = proposals[proposalId];
        return (proposal.description, proposal.votesFor, proposal.votesAgainst, proposal.executed);
    }

    function getProposalCount() public view returns (uint256) {
        return proposalCount;
    }

    function getProposalVotes(uint256 proposalId) public view returns (uint256, uint256) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal memory proposal = proposals[proposalId];
        return (proposal.votesFor, proposal.votesAgainst);
    }

    function getProposalExecutionStatus(uint256 proposalId) public view returns (bool) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal memory proposal = proposals[proposalId];
        return proposal.executed;
    }

    function contribute() public payable {
        balances[msg.sender] += msg.value;
        totalContributions += msg.value;
    }

    function withdrawFunds(uint256 amount) public {
        require(amount <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit FundsWithdrawn(amount);
    }
}
