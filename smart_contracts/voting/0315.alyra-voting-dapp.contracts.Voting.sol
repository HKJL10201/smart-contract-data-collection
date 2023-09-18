//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./Ownable.sol";

/// @title A "one shot" voting contract
/// @author Adrien G
/// @notice You can use this contract for test purposes only
/// @dev All function calls are currently implemented without side effects
/// @custom:educational This is an educational contract.
contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    WorkflowStatus public state;

    address[] private whiteListedVoters;
    mapping(address => Voter) private addressToVoter;

    Proposal[] private proposals;

    uint256 public totalVotes;
    uint256 public winningProposalId;
    uint256[] public proposalVoteCountEqualities;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    constructor() {
        state = WorkflowStatus.RegisteringVoters;
    }

    /// @notice Return the complete list of registred voter addresses
    function getWhitelistedVoters() public view returns (address[] memory) {
        return whiteListedVoters;
    }

    /// @notice Return the voter details
    /// @param voterAddress The desired voter address
    function getVoterDetails(address voterAddress)
        public
        view
        returns (Voter memory)
    {
        return addressToVoter[voterAddress];
    }

    /// @notice Return a voter vote
    /// @param voterAddress The desired voter address
    /// @return Proposal id
    function getVoterVote(address voterAddress) public view returns (uint256) {
        require(
            addressToVoter[voterAddress].isRegistered,
            "This address does not belong to registered voters."
        );

        require(
            addressToVoter[voterAddress].hasVoted,
            "Vote not submitted yet."
        );

        return addressToVoter[voterAddress].votedProposalId;
    }

    /// @notice Return the complete list of proposals
    function getProposals() public view returns (Proposal[] memory) {
        return proposals;
    }

    /// @notice Return proposal details
    /// @param _proposalId The desired proposal identifier
    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (Proposal memory)
    {
        return proposals[_proposalId];
    }

    /// @notice Return proposal ids where vote count is the same than the winner
    /// @dev if the array is not empty, it means there an equality after the vote tallying
    function getProposalVoteCountEqualities()
        public
        view
        returns (uint256[] memory)
    {
        return proposalVoteCountEqualities;
    }

    /// @notice Return winning proposal details
    function getWinner() public view returns (Proposal memory) {
        require(
            state == WorkflowStatus.VotesTallied,
            "The winning proposal is not defined yet."
        );

        require(
            proposalVoteCountEqualities.length == 0,
            "There is an equality between some proposals."
        );

        return proposals[winningProposalId];
    }

    function addVoter(address _voterAddress) public onlyOwner {
        require(
            state == WorkflowStatus.RegisteringVoters,
            "You can no longer add voters."
        );

        require(
            _voterAddress != address(0),
            "You must add a valid ETH address."
        );

        require(
            addressToVoter[_voterAddress].isRegistered == false,
            "Voter already added."
        );

        whiteListedVoters.push(_voterAddress);
        addressToVoter[_voterAddress].isRegistered = true;

        emit VoterRegistered(_voterAddress);
    }

    function startProposalSession() public onlyOwner {
        require(whiteListedVoters.length > 1, "Voting system need voters !");
        require(
            state == WorkflowStatus.RegisteringVoters,
            "You can no longer start the proposal session."
        );

        WorkflowStatus oldStatus = state;
        state = WorkflowStatus.ProposalsRegistrationStarted;

        emit WorkflowStatusChange(oldStatus, state);
    }

    function submitProposal(string memory _description) public {
        require(
            state == WorkflowStatus.ProposalsRegistrationStarted,
            "You can no longer submit a proposal."
        );

        require(
            addressToVoter[msg.sender].isRegistered,
            "Submit denied because participant does not belong to registered voters."
        );

        // https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity/82739
        string memory empty = "";
        require(
            keccak256(bytes(_description)) != keccak256(bytes(empty)),
            "Proposal can't be empty."
        );

        proposals.push(Proposal(_description, 0));
        uint256 proposalId = proposals.length - 1;

        emit ProposalRegistered(proposalId);
    }

    function endProposalSession() public onlyOwner {
        require(
            proposals.length > 1,
            "Voting system needs 2 proposals at least !"
        );
        require(
            state == WorkflowStatus.ProposalsRegistrationStarted,
            "You can no longer end the proposal session."
        );

        WorkflowStatus oldStatus = state;
        state = WorkflowStatus.ProposalsRegistrationEnded;

        emit WorkflowStatusChange(oldStatus, state);
    }

    function startVotingSession() public onlyOwner {
        require(
            state == WorkflowStatus.ProposalsRegistrationEnded,
            "You can no longer start the voting session."
        );

        WorkflowStatus oldStatus = state;
        state = WorkflowStatus.VotingSessionStarted;

        emit WorkflowStatusChange(oldStatus, state);
    }

    function voteForProposal(uint256 _proposalId) public {
        require(
            state == WorkflowStatus.VotingSessionStarted,
            "You can no longer vote for a proposal."
        );

        Voter storage currentVoter = addressToVoter[msg.sender];

        require(
            currentVoter.isRegistered,
            "You are not registered for voting."
        );

        require(currentVoter.hasVoted == false, "You cannot vote twice.");

        Proposal storage votedProposal = proposals[_proposalId];

        currentVoter.votedProposalId = _proposalId;
        currentVoter.hasVoted = true;

        votedProposal.voteCount++;

        Proposal storage tempWinningProposal = proposals[winningProposalId];

        // Edge case for first vote
        if (totalVotes == 0) {
            winningProposalId = _proposalId;
        } else if (votedProposal.voteCount > tempWinningProposal.voteCount) {
            winningProposalId = _proposalId;

            delete proposalVoteCountEqualities;
        } else if (votedProposal.voteCount == tempWinningProposal.voteCount) {
            // Handle potental vote equality
            proposalVoteCountEqualities.push(winningProposalId); // Store old winner
            winningProposalId = _proposalId; // Update new winner
        }

        totalVotes++;

        emit Voted(msg.sender, _proposalId);
    }

    function endVotingSession() public onlyOwner {
        require(
            state == WorkflowStatus.VotingSessionStarted,
            "You can no longer end the voting session."
        );

        require(totalVotes != 0, "Nobody has voted yet.");

        WorkflowStatus oldStatus = state;
        state = WorkflowStatus.VotingSessionEnded;

        emit WorkflowStatusChange(oldStatus, state);
    }

    // Determiner le gagnant au moment du vote
    function tallyingVotes() public onlyOwner {
        require(
            state == WorkflowStatus.VotingSessionEnded,
            "You can start yet tailling the votes."
        );

        WorkflowStatus oldStatus = state;
        state = WorkflowStatus.VotesTallied;

        emit WorkflowStatusChange(oldStatus, state);
    }
}
