// SPDX-License-Identifier: GPL-3.0

pragma solidity  ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract voting  is Ownable {

// struct imposée

   struct Voter {
      bool isRegistered;
      bool hasVoted;
      uint votedProposalId;
   }

   struct Proposal {
      string description;
      uint voteCount;
   }


// enum imposé
    enum WorkflowStatus{
      RegisteringVoters,
      ProposalsRegistrationStarted,
      ProposalsRegistrationEnded,
      VotingSessionStarted,
      VotingSessionEnded,
      VotesTallied}

     WorkflowStatus  status;

   
   uint winningProposalId;
   mapping(address=> Voter) public voters;
   Proposal[] public proposals; 
   mapping(address => bool) hasVoted;

 

// events

   event VoterRegistered(address voterAddress);
   event ProposalRegistered(uint proposalId);
   event Voted (address voter, uint proposalId);
   event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

  

// 1: the admin register the whitelist and identify the electors by their ethereum address
      
      
   
   function registeringVoter(address  voterAddress) onlyOwner public  {
      require(!voters[msg.sender].isRegistered);
      voters[msg.sender].isRegistered = true;
      emit VoterRegistered(voterAddress); 
   
   }

// 2: the administrator start the session of enregistrement de la proposition
     

   function startingRegistration() onlyOwner public {
       WorkflowStatus previousStatus = status;
       status = WorkflowStatus.ProposalsRegistrationStarted;
       emit WorkflowStatusChange( previousStatus, status);
   }
   

   
// 3: the electors on the list can choose their proposal

  
    
   function proposeProposal(string memory _description) public  {
      require(voters[msg.sender].isRegistered = true);
      require(hasVoted[msg.sender] == false, "You already voted");
      require(status != WorkflowStatus.ProposalsRegistrationEnded);
      proposals.push(Proposal({
         description: _description,
         voteCount:0
      }));
      
      
      
   }
   // test
   function getProposalId (address voter) public returns (uint){
      uint proposalId = voters[voter].votedProposalId;
      emit ProposalRegistered(proposalId);
      
      return proposalId;
   }

   
   
   
   function EndingRegistration() onlyOwner public {
      WorkflowStatus previousStatus = status;
      status = WorkflowStatus.ProposalsRegistrationEnded;
      emit WorkflowStatusChange( previousStatus, status);
   }
// 4: the electors on the whilists are authorised (require) to vote until the vote is active
  
   function startVoting() onlyOwner public {
      
      require(status == WorkflowStatus.ProposalsRegistrationEnded);
      WorkflowStatus previousStatus = status;
      status = WorkflowStatus.VotingSessionStarted;
      emit WorkflowStatusChange( previousStatus, status);
   }
  

  function vote(address voter ,uint proposalId)  public  {
     Voter storage sender = voters[msg.sender];
     require(voters[msg.sender].isRegistered = true);
      require(hasVoted[msg.sender] == false, "You already voted");
      require(status != WorkflowStatus.VotingSessionEnded);
       sender.hasVoted= true;
       sender.votedProposalId = proposalId;
       proposals[proposalId].voteCount += 1;
       emit Voted (voter,proposalId);
  }
  
 // 5: the admin end the session of vote
  

   function stopVoting() onlyOwner public {
      require(status == WorkflowStatus.VotingSessionStarted);
      WorkflowStatus previousStatus = status;
      status = WorkflowStatus.VotingSessionEnded;
      emit WorkflowStatusChange( previousStatus, status);
      
   }


   // 6: the admin count the votes
 function count() onlyOwner public returns (uint winningProposal_) {
   require( status == WorkflowStatus.VotingSessionEnded);
    uint winningVoteCount = 0;
     for (uint p = 0; p < proposals.length; p++){
        if (proposals[p].voteCount > winningVoteCount){
           winningVoteCount = proposals[p].voteCount;
           winningProposal_ = p ;
           status = WorkflowStatus.VotesTallied;
           winningProposalId = winningProposal_;
           return  winningProposalId ;
      
        } else if (proposals[p].voteCount == winningVoteCount) {
            status = WorkflowStatus.VotesTallied;
        console.log("there is a draw!");
      } else{
       console.log("something went wrong there are no proposals given");
      }
     }
 

  }
 

   // 7:imposé Votre smart contract doit définir un uint winningProposalId qui représente l’id du gagnant ou une fonction getWinner qui retourne le gagnant.
    // function get winner i s the highest sum of proposal if there is an egality give two first values 
    // 8: everybody can verify the details of the winning proposal
     
   function getwinner() public  view returns (uint winner_) {
      require(status == WorkflowStatus.VotesTallied);
     winner_ = winningProposalId;
    
    }
   

}

