// SPDX-License-Identifier: GPL-3.0

/**
 * @title systemeVoteWorkflow.sol
 * @dev Le contrat permet de gerer le Workflow dans lequel se situe le vote.
 */
 
import "@OpenZeppelin/contracts/access/Ownable.sol";

pragma solidity 0.7.6;
contract SystemeVoteWorkflow is Ownable {
    
    WorkflowStatus public workflowStatus;

        enum WorkflowStatus {
            RegisteringVoters,
            ProposalsRegistrationStarted,
            ProposalsRegistrationEnded,
            VotingSessionStarted,
            VotingSessionEnded,
            VotesTallied
            }

        event VoterRegistered(address voterAddress);
        event ProposalsRegistrationStarted();
        event ProposalsRegistrationEnded();
        event ProposalRegistered(uint proposalId);
        event VotingSessionStarted();
        event VotingSessionEnded();
        event Voted (address voter, uint proposalId);
        event VotesTallied();
        event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
        
        
      modifier rightStatus(WorkflowStatus _statusToCheck){
        require (workflowStatus == _statusToCheck, "you are not in the right status");
        _;
    }
        
       
    ///@dev owner starting proposal session    
    function openingProposalSession () public onlyOwner rightStatus(WorkflowStatus.RegisteringVoters){
        
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit ProposalsRegistrationStarted();
        emit WorkflowStatusChange (WorkflowStatus.RegisteringVoters, workflowStatus);
    }
    

    ///@dev owner closing proposal session    
    function closingProposalSession () public  onlyOwner rightStatus(WorkflowStatus.ProposalsRegistrationStarted){
        
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit ProposalsRegistrationEnded();
        emit WorkflowStatusChange (WorkflowStatus.ProposalsRegistrationStarted, workflowStatus);
    }

    ///@dev oppening voting session    
    function openingVoting () public  onlyOwner rightStatus(WorkflowStatus.ProposalsRegistrationEnded){
        
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit VotingSessionStarted();
        emit WorkflowStatusChange (WorkflowStatus.ProposalsRegistrationEnded, workflowStatus);
    }
    
    ///@dev closing voting session
    function closingVoting () public onlyOwner rightStatus(WorkflowStatus.VotingSessionStarted){
        
        workflowStatus = WorkflowStatus.VotingSessionEnded;
         emit VotingSessionEnded();
         emit WorkflowStatusChange (WorkflowStatus.VotingSessionStarted, workflowStatus);
    }

 
    ///@dev ending session    
    function sessionOver() internal onlyOwner rightStatus(WorkflowStatus.VotingSessionEnded) {
        
        workflowStatus = WorkflowStatus.VotesTallied;
         emit VotesTallied();
         emit WorkflowStatusChange (WorkflowStatus.VotingSessionEnded, workflowStatus);
    }
}