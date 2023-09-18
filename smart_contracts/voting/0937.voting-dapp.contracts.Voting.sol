// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Système de vote 
/// @author Hoby
/// @notice Un contrat qui permet de gérer un sytème de vote
contract Voting is Ownable {

    // arrays for draw, uint for single
    // uint[] winningProposalsID;
    // Proposal[] public winningProposals;
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
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public workflowStatus;
    Proposal[] proposalsArray;
    mapping (address => Voter) voters;


    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(string proposalDescription);
    event Voted (address voter, uint proposalId);

    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }
    
    // on peut faire un modifier pour les états

    // ::::::::::::: GETTERS ::::::::::::: //

    /// @notice Get a voter by address
    /// @param _addr The voter's address
    /// @return Voter The voter found
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
    /// @notice Get a proposal by id
    /// @param _id The proposal's id
    /// @return Proposal The proposal found
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

 
    // ::::::::::::: REGISTRATION ::::::::::::: // 

    /// @notice Enregistrement d'un votant par l'admin dans la liste blanche
    /// @param _addr addresse du votant
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 
    /* facultatif
     * function deleteVoter(address _addr) external onlyOwner {
     *   require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
     *   require(voters[_addr].isRegistered == true, 'Not registered.');
     *   voters[_addr].isRegistered = false;
     *  emit VoterRegistered(_addr);
    }*/

    // ::::::::::::: PROPOSAL ::::::::::::: // 

    /// @notice Enregistrer une proposition d'un electeur
    /// @param _desc description de la proposition
    function addProposal(string calldata _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        // voir que desc est different des autres
        require(isNewProposal(_desc), unicode"Proposition déjà enregistrée");

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(_desc);
    }

    // ::::::::::::: VOTE ::::::::::::: //

    /// @notice Vote d'un élécteur 
    /// @param _id l'id de la proposition à voter
    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id <= proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //

    /* on pourrait factoriser tout ça: par exemple:
    *
    *  modifier checkWorkflowStatus(uint  _num) {
    *    require (workflowStatus=WorkflowStatus(uint(_num)-1, "bad workflowstatus");
    *    require (num != 5, "il faut lancer tally votes");
    *    _;
    *  }
    *
    *  function setWorkflowStatus(WorkflowStatus _num) public checkWorkflowStatus( _num) onlyOwner {
    *    WorkflowStatus old = workflowStatus;
    *    workflowStatus = WorkflowStatus(_num);
    *    emit WorkflowStatusChange(old, workflowStatus);
    *   } 
    *
    *  ou plus simplement:
    *  function nextWorkflowStatus() onlyOwner{
    *    require (uint(workflowStatus)!=4, "il faut lancer tallyvotes");
    *    WorkflowStatus old = workflowStatus;
    *    workflowStatus= WorkflowStatus(uint (workflowstatus) + 1);
    *    emit WorkflowStatusChange(old, workflowStatus);
    *  }
    *
    */ 

    /// @notice Démarrer la session d'enregistrement de la proposition
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /// @notice Arret de la session d'enregistrement des propositions
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /// @notice Demarrer la session de vote
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /// @notice Arreter la session de vote
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /// @notice Comptabiliser les votes des électeurs
   function tallyVotes() external onlyOwner {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
       uint _winningProposalId;
      for (uint256 p = 0; p < proposalsArray.length; p++) {
           if (proposalsArray[p].voteCount > proposalsArray[_winningProposalId].voteCount) {
               _winningProposalId = p;
          }
       }
       winningProposalID = _winningProposalId;
       
       workflowStatus = WorkflowStatus.VotesTallied;
       emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

    /// @dev Check if the proposal already exists 
    /// @param _proposalDescription description of the proposal to check
    /// @return true if not exists false otherwise
    function isNewProposal(string calldata _proposalDescription) private view returns(bool) {

        for(uint i=0; i < proposalsArray.length; i++) {
            if ( keccak256(abi.encodePacked( proposalsArray[i].description) ) == keccak256(abi.encodePacked(_proposalDescription)) ) {
                return false;
            }
        }
        return true;
    }
}