//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./structures/Elements.sol";
import "./Proposal.sol";

/// @title User (voter) Contract
/// @author Juan Felipe Aranguren
/// @notice Manages voter operations with checks
/// @dev This is a CRUD program with validations

contract User is Ownable {
    /// @notice voters mapping.
    mapping(address => Voter) public voters;
    /// @notice a voter address array
    address[] public voterList;
    /// @notice a Proposal contract object
    Proposal public proposal;

    event VoterCreated(address indexed id, string name);

    constructor(address _proposalId) {
        proposal = Proposal(_proposalId);
    }

    function _getVoterStatus() private view returns (bool) {
        return voters[msg.sender].hasVoted;
    }

    /// @notice searchs for duplicate users
    modifier userExists() {
        bool userAlreadyCreated;
        if (voterList.length > 0) {
            for (uint256 i = 0; i < voterList.length; i++) {
                userAlreadyCreated = voterList[i] == msg.sender;
            }
        }

        require(!userAlreadyCreated, "User already exists!");
        _;
    }

    function newVoter(string memory _name, uint256 _age) public userExists {
        address id = msg.sender;

        voters[id].name = _name;
        voters[id].age = _age;
        voters[id].hasVoted = false;
        voters[id].proposalId = 0;

        emit VoterCreated(id, _name);

        voterList.push(id);
    }

    function getVoter() public view returns (Voter memory) {
        Voter memory voter = voters[msg.sender];
        return voter;
    }

    function getVoters() public view returns (address[] memory) {
        return voterList;
    }

    function getVotersCount() public view returns (uint256) {
        return voterList.length;
    }

    /// @notice lets users build proposals
    function buildProposal(
        string memory _proposalName,
        uint256 _proposalId,
        uint256 _target,
        uint256 _createdAt,
        uint256 _lastVotedAt
    ) public {
        string memory voterName;
        voterName = voters[msg.sender].name;

        Creator memory creator;
        creator.id = msg.sender;
        creator.name = voterName;

        proposal.newProposal(
            _proposalId,
            _proposalName,
            _target,
            _createdAt,
            _lastVotedAt,
            creator
        );
    }

    function getProposal(uint256 _id)
        public
        view
        returns (ProposalForm memory)
    {
        return proposal.getProposal(_id);
    }

    /// @notice lets users vote for proposals. 1 user, 1 vote.
    function voteProposal(uint256 _proposalId, uint256 _lastVotedAt) public {
        Voter storage voter = voters[msg.sender];
        require(!voter.hasVoted, "User has already voted.");

        voter.hasVoted = true;
        voter.proposalId = _proposalId;

        proposal.proposalVote(_proposalId, _lastVotedAt);
    }

    /// @notice lets users retrieve their vote (for whatever reason)
    function retrieveVote(uint256 _id, uint256 time) public {
        bool userHasVoted = _getVoterStatus();
        require(userHasVoted, "User hasn't voted yet");

        proposal.liquidVote(_id, time);
        Voter storage voter = voters[msg.sender];
        voter.hasVoted = false;
        voter.proposalId = 0;
    }

    /// @notice Erases an existing proposal. May be called by owner (admin) only 
    /// @dev onlyOwner is a function modifier straight from OpenZeppelin access contracts
    /// @param _id The proposal ID.
    function deleteProposal(uint _id) external onlyOwner {
        proposal.proposalErase(_id);
    }
}
