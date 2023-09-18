// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/// @title A simulator for Vote
/// @author Sadikovic.Rusmir
/// @notice You can use this contract for organise basic vote 
/// @dev All function calls are currently implemented without side effects

contract Voting is Ownable {

    ///@notice permit to organise sessions of Votes, Voters to make proposals and vote for proposals with winning proposals at the end
    ///@notice proposal number who win the vote at the end of session

    uint public winningProposalID;
    ///@notice return Struct isRegistered, hasVoted return boolen 
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    ///@notice Proposals déscritpion 
    ///@dev use voteCount to count winnerproposal
    struct Proposal {
        string description;
        uint voteCount;
    }
    ///@notice workflow permit to control steps of voting session by Owner
    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
        ///@dev workflowStatus status contain all enums of WorkflowStatus
        ///@dev Arr of proposals are not public 
    WorkflowStatus public workflowStatus;
    Proposal[] proposalsArray;
    mapping (address => Voter) voters;
        ///@notice valid eth adress is require for participate to vote session.
        ///@dev all voters adresses are in maping voters
        ///@dev you must use proposalID event to add vote
        ///@notice all events can be catch et display for users informations,
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);
    
        ///@notice modifier, allow only registered addresses by owner to participate to vote session
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }
    
    
    // ::::::::::::: GETTERS ::::::::::::: //
        ///@return voter Eth adress, view only for registered voters
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
        ///@return array of proposals, uint _id, only for registered voters
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

        ///@dev is better to use a different display for owner and voters 
    // ::::::::::::: REGISTRATION ::::::::::::: // 
        ///@notice permit to add voter adress in whitelist, by owner only && if workflow is ind status RegisteringVoters && voter is not registered
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 

    // ::::::::::::: PROPOSAL ::::::::::::: // 
        ///@notice use _desc string to add one proposal, limited to 1000 proposals
    function addProposal(string calldata _desc) external onlyVoters {
        require(proposalsArray.length < 1000,  "Maximum proposals") ;
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length-1);
    }
        ///@notice emit Proposalregistered event il array
    // ::::::::::::: VOTE ::::::::::::: //

        ///@notice you can vote for uint _id proposal with this function
    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        emit Voted(msg.sender, _id);
    }
        ///@notice emit Voted event in array 
    // ::::::::::::: STATE ::::::::::::: //

        ///@notice the owner start registering proposals, registered voters can make proposals
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);
        
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }
        ///@notice the owner set end of registering  voters can't make any proposals after that
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }
///@notice the owner start voting session, registered Voters can vote now
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }
///@notice the owner end voting session no more vote are possibles 
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

///@notice the owner tally Votes and the proposal with higer number of votes wins
///@dev the winning proposal is in winningProposalID 
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
}
