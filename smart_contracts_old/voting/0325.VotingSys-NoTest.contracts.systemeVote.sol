// SPDX-License-Identifier: GPL-3.0

/**
 * @title systemeVote
 * @dev Le contrat permet d'enregistrer une liste de voter, repurerer leurs propositions,
 * etablir un vote pour la meilleure proposition et definir la proposition gagnante. Celle 
 * pour laquelle le plus de gens ont vote. Le contrat systemeVoteWorflow est necessaire
 * pour le bon fonctionnement de ce contrat. Comme son nom l'indique, il gere tout le Workflow.
 * */

import "./systemeVoteWorkflow.sol";

pragma solidity 0.7.6;
pragma abicoder v2;
 
contract SystemeVote is SystemeVoteWorkflow {

    uint winningProposalId;
    uint idProposal;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
        
    struct Proposal {
        string description;
        uint voteCount;
    }    
        
    mapping (address => Voter) public whiteList;
    mapping (string => Proposal) public listProposals;
    mapping (uint => Proposal) public  idsProposals;
    

    modifier registred (){
           
           require (whiteList[msg.sender].isRegistered == true, "you are not registered on the voter list");
           _;
       }
       

    ///@dev owner adding whitelist address
    function whiteListed (address _voterAddress) public onlyOwner rightStatus(WorkflowStatus.RegisteringVoters){ 
        
        require (!whiteList[_voterAddress].isRegistered, "Voter alredy registred");
        whiteList[_voterAddress].isRegistered = true;
        emit VoterRegistered(_voterAddress);
    }
    
    ///@dev whiteListed addresses making proposals
    function propositions (string memory _proposal) public registred rightStatus(WorkflowStatus.ProposalsRegistrationStarted) { 
        
        require (bytes(listProposals[_proposal].description).length == 0, "This proposal has already been submitted"); 
        listProposals[_proposal].description = _proposal;
        idsProposals[idProposal] = Proposal(_proposal, 0);
        emit ProposalRegistered (idProposal);
        idProposal ++;
    }
    
    ///@dev whiteListed addresses make a unique vote and at the same time the program is counting the winning proposal    
    function vote (uint _idChooseProposal) public registred rightStatus( WorkflowStatus.VotingSessionStarted){
        
        require(bytes(idsProposals[_idChooseProposal].description).length != 0, "This proposal doesn't exist ");
        require(!whiteList[msg.sender].hasVoted, "You've voted already");
        whiteList[msg.sender] = Voter( true, true, _idChooseProposal);
        uint currentProposalVotes = idsProposals[_idChooseProposal].voteCount += 1;
        
        if (currentProposalVotes > winningProposalId) {
            winningProposalId = _idChooseProposal;
        }
        emit Voted (msg.sender, _idChooseProposal);
    }
    
    ///@dev the owner announce the end of the vote 
    function comptageVotes() public onlyOwner rightStatus (WorkflowStatus.VotingSessionEnded) {
        
       sessionOver();
    }
    
    ///@dev showing the winner details
    function getWinner() public view rightStatus(WorkflowStatus.VotesTallied) returns (Proposal memory) {
        
        return idsProposals[winningProposalId];
    }
    
    ///@dev showing the vote 
    function getVote (address _address) public view rightStatus(WorkflowStatus.VotesTallied) returns(uint){
        
        require(whiteList[_address].isRegistered, "This person is not on the whitelist ");
        return whiteList[_address].votedProposalId;
    }
}