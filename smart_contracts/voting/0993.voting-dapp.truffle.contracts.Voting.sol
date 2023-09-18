// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * Voting contract is a simple voting system.
 * It allows the owner to registered voters.
 * Registred voters can submit proposals during the proposal registration period
 * and can vote for a proposition during the voting session.
 *
 * Vote is not secret for registered voters.
 * Each registered voter can see each other vote at the end of the process.
 * Registered Proposal which has the more votes will win.
 */
contract Voting is Ownable {

    uint public winningProposalID;
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum  WorkflowStatus {
        RegisteringVoters, // registering voters period
        ProposalsRegistrationStarted, // registering proposals period
        ProposalsRegistrationEnded, // end of registering proposals
        VotingSessionStarted, // voting session period
        VotingSessionEnded, // end of voting session
        VotesTallied // votes are tallied and results could be announced
    }

    WorkflowStatus public workflowStatus;
    Proposal[] proposalsArray;
    mapping (address => Voter) voters;


    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);
    
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }

    /**
     * @dev get a voter
     * @param _addr address of the voter
     */
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
    /**
     * @dev get the proposal
     * @param _id id of the proposal
     */
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    } 

    /**
     * @dev Register a new voter in the whitelist. Only owner can run this method.
     * The workflowStatus has to be in RegisteringVoters state.
     * @param _addr the voter adress to register.
     **/
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }

    /**
     * @dev Register a proposal. Only registered voters can register a proposal.
     * The workflowStatus has to be in ProposalsRegistrationStarted state.
     * @param _desc description of the proposal to add.
     */
    function addProposal(string calldata _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);

        emit ProposalRegistered(proposalsArray.length-1);
    }

    
    /**
     * @dev Vote for a proposal. Only registered voters can vote. A voter can vote only during the voting session, and only once.
     * @param _id id of the proposal ( = index of the proposal in the proposals array)
     * The workflowStatus has to be in VotingSessionStarted state.
     */
    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        // compute the temporary winner
        if (proposalsArray[_id].voteCount > proposalsArray[winningProposalID].voteCount) {
            winningProposalID = _id;
        }
            

        emit Voted(msg.sender, _id);
    }

    /**
     * @dev Use this method to change the workflow status to ProposalsRegistrationStarted state. 
     * Only owner can run this method.
     **/
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);
        
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /**
     * @dev Use this method to change the workflow status to ProposalsRegistrationEnded state. 
     * Only owner can run this method.
     **/
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /**
     * @dev Use this method to change the workflow status to VotingSessionStarted state. 
     * Only owner can run this method.
     **/
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /**
     * @dev Use this method to change the workflow status to VotingSessionEnded state. 
     * Only owner can run this method.
     **/
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /**
     * @dev Use this method to change the workflow status to VotesTallied state. 
     * Only owner can run this method.
     */
   function tallyVotes() external onlyOwner {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
       workflowStatus = WorkflowStatus.VotesTallied;
       emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
}