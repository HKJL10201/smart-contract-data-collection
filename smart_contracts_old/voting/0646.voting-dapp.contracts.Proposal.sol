//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./structures/Elements.sol";

/// @title Proposal Contract
/// @author Juan Felipe Aranguren
/// @notice Manages proposal operations with checks
/// @dev This is a CRUD program with validations

contract Proposal {

    /// @notice proposals mapping. The uint is its unique ID
    mapping(uint256 => ProposalForm) public proposals;
    /// @notice holds IDs of all created proposals
    uint256[] public proposalList;

    event ProposalVoted(
        uint256 indexed proposalId,
        address user,
        uint256 _lastVotedAt
    );
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed createdBy,
        string name,
        uint256 createdAt
    );
    event ProposalReachedTarget(uint256 indexed proposalId, uint256 target);
    event VoteWasRetrieved(
        uint256 indexed proposalId,
        address indexed user,
        uint256 time
    );

    /// @notice checks for duplicated proposals
    modifier proposalIsDuplicated(uint256 _id) {
        string
            memory duplicatedProposalMessage = "Proposal with same ID already exists!";
        bool proposalAlreadyCreated;
        if (proposalList.length > 0) {
            for (uint256 i = 0; i < proposalList.length; i++) {
                proposalAlreadyCreated = proposalList[i] == _id;
            }
        }
        require(!proposalAlreadyCreated, duplicatedProposalMessage);
        _;
    }

    /// @notice checks for inactive or non-existing proposals
    modifier proposalIsActive(uint256 _id) {
        bool propIsActive = proposals[_id].isActive;
        require(propIsActive, "Proposal is inactive or doesn't exist");
        _;
    }

    /// @notice checks for completed proposals
    /// @dev voteCount == goal (set ammount of votes)
    function _proposalHasReachedGoal(uint256 _id) private returns (bool) {
        uint256 votes = proposals[_id].voteCount;
        uint256 goal = proposals[_id].goal;

        if (votes == goal) {
            emit ProposalReachedTarget(_id, goal);

            ProposalForm storage prop = proposals[_id];
            prop.isActive = false;
            return true;
        }
        return false;
    }

    /// @notice a proposal is created. ID must be unique
    function newProposal(
        uint256 _id,
        string memory _name,
        uint256 _goal,
        uint256 _createdAt,
        uint256 _lastVotedAt,
        Creator memory _creator
    ) public proposalIsDuplicated(_id) {
        proposals[_id].name = _name;
        proposals[_id].goal = _goal;
        proposals[_id].createdAt = _createdAt;
        proposals[_id].isActive = true;
        proposals[_id].lastVotedAt = _lastVotedAt;
        proposals[_id].voteCount = 0;
        proposals[_id].createdBy = _creator;

        emit ProposalCreated(_id, msg.sender, _name, _createdAt);

        proposalList.push(_id);
    }

    function getProposal(uint256 _id)
        public
        view
        returns (ProposalForm memory)
    {
        ProposalForm memory proposal = proposals[_id];
        return proposal;
    }

    function getProposalStatus(uint256 _id) public view returns (bool) {
        return proposals[_id].isActive;
    }

    function getProposalCount() public view returns (uint256) {
        return proposalList.length;
    }

    function proposalVote(uint256 _id, uint256 _lastVotedAt)
        public
        proposalIsActive(_id)
    {
        bool goalReached = _proposalHasReachedGoal(_id); // event below...
        require(!goalReached, "Proposal has reached its target");

        ProposalForm storage prop = proposals[_id];
        uint256 vote = 1;

        prop.voteCount += vote;
        prop.lastVotedAt = _lastVotedAt;

        emit ProposalVoted(_id, msg.sender, _lastVotedAt);
    }

    /// @notice handles the vote retrieval as a small "Direct Democracy" mechanism
    /// @dev notice a that a vote is substracted and also the lastVotedAt timestamp is updated
    function liquidVote(uint256 _id, uint256 time)
        public
        proposalIsActive(_id)
    {
        ProposalForm storage prop = proposals[_id];
        uint256 vote = 1;

        prop.voteCount -= vote;
        prop.lastVotedAt = time;
        emit VoteWasRetrieved(_id, msg.sender, time);
    }

    /// @notice Implements the proposal delete only if total vote count isn't greater than 35% of the target
    /// @dev Looks like solidity doesn't handle float numbers well. A little hack was necessary (see: percentageAchieved)
    function proposalErase(uint _id) public proposalIsActive(_id) {
        uint256 votes = proposals[_id].voteCount;
        uint256 goal = proposals[_id].goal;
        uint256 percentageAchieved = (votes * 100) / goal;

        require(percentageAchieved < 35, "35% vote treshold achieved.");

        delete proposals[_id];
    }
}
