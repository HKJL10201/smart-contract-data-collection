// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Voting {

    enum VoteStates{ Yes, No, Absent }
    uint constant VOTE_THRESHOLD = 10;

    struct Proposal {
        address target;
        bytes data;
        uint yesCount;
        bool executed;
        uint noCount;
        mapping(address => VoteStates) votes;
    }

    Proposal[] public proposals;

    event ProposalCreated(uint);
    event VoteCast(uint, address);

    mapping(address => bool) public members;

    constructor(address[] memory _members) {
        for(uint i = 0; i < _members.length; i++) {
            members[_members[i]] = true;
        }
        members[msg.sender] = true;
    }

    // Create a new proposal to call 'target' with 'data'
    function newProposal(address _target, bytes memory _data) external {
        require(members[msg.sender]);
        emit ProposalCreated(proposals.length);
        Proposal storage proposal = proposals.push();
        proposal.target = _target;
        proposal.data = _data;
    }

    // Vote on proposal #`_proposalId`, `_yes` for yes, `_no` for no
    function castVote(uint _proposalId, bool _yes) external {
        require(members[msg.sender]);
        Proposal storage proposal = proposals[_proposalId];

        if(proposal.votes[msg.sender] == VoteStates.Yes) {
            proposal.yesCount--;
        } else if(proposal.votes[msg.sender] == VoteStates.No) {
            proposal.noCount--;
        }

        // Check if the proposal is still open
        if (_yes) {
            proposal.yesCount++;
        } else {
            proposal.noCount++;
        }

        proposal.votes[msg.sender] = _yes ? VoteStates.Yes : VoteStates.No;
        emit VoteCast(_proposalId, msg.sender);

        if(proposal.yesCount >= VOTE_THRESHOLD && !proposal.executed) {
            (bool success, ) = proposal.target.call(proposal.data);
            require(success);
        }
    }
}
