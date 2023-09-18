// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title A simulator for Voting
 * @author Alyra School
 * @notice You can use this contract for only the most basic simulation
 * @dev All function calls are currently implemented without side effects
 * @custom:experimental This is an experimental contract.
 */

contract Voting is Ownable {
    // @notice ID of proposal winning vote
    uint public winningProposalID;

    // @notice . structure of voter (registered)
    // @notice . isRegistred for check if admin on contract validate
    // @notice . hasVoted for check if voter has already voted
    // @notice . votedProposalId for check for which proposal has voted
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    // @notice . structure of proposal (By voter)
    // @notice . description of proposal info
    // @notice . voteCount for check number vote contain proposal
    struct Proposal {
        string description;
        uint voteCount;
    }

    // @notice . Status of contract for actions
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    // @notice . static status of contract
    WorkflowStatus public workflowStatus;
    // @notice . Array of proposal (active)
    Proposal[] proposalsArray;
    // @notice . Mapping of struct Voter
    mapping(address => Voter) voters;

    // @notice  . Emitted when new voter is registered by admin of contract
    event VoterRegistered(address voterAddress);

    // @notice  . Emmited when the workflow status has changed by admin of contract
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    // @notice  . Emmited when new voter has registred by admin of contract
    event ProposalRegistered(uint proposalId);
    // @notice  . Emmited when voters vote on proposal
    event Voted(address voter, uint proposalId);

    // @notice  . Check if msg.sender is a Voter
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }

    // ::::::::::::: GETTERS ::::::::::::: //

    /**
     * @notice  . Get one voter on mapping voters with address params
     * @dev     . By struct Voter
     * @param   _addr  . address of the voter to be retrieved
     * @return  Voter  . struct of voter by the address
     */
    function getVoter(
        address _addr
    ) external view onlyVoters returns (Voter memory) {
        return voters[_addr];
    }

    /**
     * @notice  . Get one proposal by id
     * @dev     . By struct Proposal
     * @param   _id  . uint of the id on proposal to be retrieved
     * @return  Proposal  . Struct of proposal by the id
     */
    function getOneProposal(
        uint _id
    ) external view onlyVoters returns (Proposal memory) {
        return proposalsArray[_id];
    }

    // ::::::::::::: REGISTRATION ::::::::::::: //

    /**
     * @notice  . Add voter by owner on static voters mapping
     * @dev     . Struct Voter on voters
     * @dev     . Emit VoterRegistered()
     * @param   _addr  . Needed address for stocking meta on voter
     */
    function addVoter(address _addr) external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters,
            "Voters registration is not open yet"
        );
        require(voters[_addr].isRegistered != true, "Already registered");

        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }

    // ::::::::::::: PROPOSAL ::::::::::::: //

    /**
     * @notice  . Add proposal by voter on static Proposal[]
     * @dev     . Struct proposal on Proposal[]
     * @dev     . Emit ProposalRegistered()
     * @param   _desc  . Needed string for description on proposal
     */
    function addProposal(string calldata _desc) external onlyVoters {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Proposals are not allowed yet"
        );
        require(
            keccak256(abi.encode(_desc)) != keccak256(abi.encode("")),
            "Vous ne pouvez pas ne rien proposer"
        ); // facultatif
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length - 1);
    }

    // ::::::::::::: VOTE ::::::::::::: //

    /**
     * @notice  . Voting on proposal by voter on voters and proposalArray
     * @dev     . set Voter on voters & increment voteCount on Proposal
     * @dev     . emit Voted()
     * @param   _id  . Needed uint of proposal by voter
     */
    function setVote(uint _id) external onlyVoters {
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "Voting session havent started yet"
        );
        require(voters[msg.sender].hasVoted != true, "You have already voted");
        require(_id < proposalsArray.length, "Proposal not found"); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //

    /**
     * @notice  . Change status to Start the registering on Proposal
     * @dev     . set workflowStatut & create first proposal (0)
     * @dev     . emit WorkflowStatusChange()
     */
    function startProposalsRegistering() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters,
            "Registering proposals cant be started now"
        );
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;

        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);

        emit WorkflowStatusChange(
            WorkflowStatus.RegisteringVoters,
            WorkflowStatus.ProposalsRegistrationStarted
        );
    }

    /**
     * @notice  . Change status to Stop the registering on Proposal
     * @dev     . set workflowStatut
     * @dev     . emit WorkflowStatusChange()
     */
    function endProposalsRegistering() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Registering proposals havent started yet"
        );
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted,
            WorkflowStatus.ProposalsRegistrationEnded
        );
    }

    /**
     * @notice  . Change status to Start the session on voting
     * @dev     . set workflowStatut
     * @dev     . emit WorkflowStatusChange()
     */
    function startVotingSession() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationEnded,
            "Registering proposals phase is not finished"
        );
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            WorkflowStatus.VotingSessionStarted
        );
    }

    /**
     * @notice  . Change status to Stop the session on voting
     * @dev     . set workflowStatut
     * @dev     . emit WorkflowStatusChange()
     */
    function endVotingSession() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "Voting session havent started yet"
        );
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionStarted,
            WorkflowStatus.VotingSessionEnded
        );
    }

    /**
     * @notice  . Change status to Tallies votes on proposal by voter & edit the proposal winning ID
     * @dev     . set workflowStatut & set winningProposalId
     * @dev     . emit WorkflowStatusChange()
     */
    function tallyVotes() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.VotingSessionEnded,
            "Current status is not voting session ended"
        );
        uint _winningProposalId;
        for (uint256 p = 0; p < proposalsArray.length; p++) {
            if (
                proposalsArray[p].voteCount >
                proposalsArray[_winningProposalId].voteCount
            ) {
                _winningProposalId = p;
            }
        }
        winningProposalID = _winningProposalId;

        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            WorkflowStatus.VotesTallied
        );
    }
}
