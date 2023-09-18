// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Voting is  Ownable {
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    
    struct Proposal {
        string description;
        uint voteCount;
    }

    WorkflowStatus status;
    uint winningProposalId;

    mapping(address => bool) whitelist;
    mapping(address => Voter) public voter;

    address[] voters;
    Proposal[] proposals;
    bool hasVoters;


    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    modifier onlyWhitelisted () {
        require(whitelist[msg.sender], "You need to be whitelisted");
        _;
    }

    function addToWhitelist (address _addr) external onlyOwner {
        require(status == WorkflowStatus.RegisteringVoters, unicode"You can't add more voter: Registering voters closed");
        hasVoters = true;
        emit VoterRegistered(_addr);
        whitelist[_addr] = true;
        voter[_addr].isRegistered = true;
        voters.push(_addr);
    }

    function changeWorkflowStatus () external onlyOwner {
        require(hasVoters, "You need to add voters");
        uint nextStatus = uint(status);
        nextStatus++;
        require(nextStatus <= 5, "You are in the last workflow status.");
        status = WorkflowStatus(nextStatus);
    }

    function resetWorkflowStatus () external onlyOwner {
        require(status == WorkflowStatus.VotesTallied, unicode"You can't reset the workflow status if it's no ended.");
        status = WorkflowStatus.RegisteringVoters;
    }


    function getWorkflowStatus () external view returns (string memory) {
        if (status == WorkflowStatus.RegisteringVoters) {
            return "Registering voters ";
        } else if (status == WorkflowStatus.ProposalsRegistrationStarted) {
            return "Proposals registration started !";
        } else if (status == WorkflowStatus.ProposalsRegistrationEnded) {
            return "Proposals registration ended !";
        } else if (status == WorkflowStatus.VotingSessionStarted) {
            return "Voting session started";
        } else if (status == WorkflowStatus.VotingSessionEnded) {
            return " Voting session ended";
        } else {
            return "Votes Tallied";
        }
    }


    function submitProposal (string calldata _description) external onlyWhitelisted {
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "Proposals registration not started or ended");
        proposals.push(Proposal(_description, 0));
    }

    function getProposalsById (uint _id) external view returns (string memory) {
        require(_id < proposals.length, "by id");
        return proposals[_id].description;
    }

    function getProposalsIds () external view returns (uint[] memory) {
        require(proposals.length > 0, "Bad id");
        uint[] memory ids = new uint[](proposals.length);

        for (uint i = 0; i < proposals.length; i++) {
            ids[i] = i;
        }
        return ids;
    }

    function applyVote (uint _proposalId) external onlyWhitelisted {
        require(status == WorkflowStatus.VotingSessionStarted, "You need to be in voting session");
        require(_proposalId <= proposals.length, unicode"This proposal id doesn't existe to see all ids do 'getProposalsIds' and 'getProposalsById' to see the description");
        emit Voted(msg.sender, _proposalId);

        voter[msg.sender].hasVoted = true;
        voter[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount++;
    }


    function countingVotes () external onlyOwner {
        require(status == WorkflowStatus.VotingSessionEnded || status == WorkflowStatus.VotesTallied, "You need to wait voting session ended");

        for (uint i = 0; i < proposals.length; i++) {
            if (winningProposalId < proposals[i].voteCount) {
                winningProposalId = proposals[i].voteCount;
            }
        }
    }

    function getWinner () external view returns(uint) {
        return winningProposalId;
    }

    
}
