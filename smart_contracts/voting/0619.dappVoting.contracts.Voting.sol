// SPDX-License-Identifier: MIT

pragma solidity 0.8.13 ;
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
* @title Study voting contract 
* @author Decentralized Stef
*/
contract Voting is Ownable {

    // arrays for draw, uint for single
    uint[] winningProposalsID;
    Proposal[] winningProposals;
    uint public winningProposalID;
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
        uint proposedProposalCount;
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
    Proposal[] public proposalsArray;
    mapping (address => Voter) private voters;


    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }

    // ::::::::::::: GETTERS ::::::::::::: //

    /** 
    * @dev get Voter infos
    * @dev only voters can interact
    * @param  _addr {address} the voter's address
    * @return Voter
     */
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
    /**
     * @dev Get Proposal from its id
     * @param  _id {uint} the proposal id
     * @return Proposal
     */
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

    /**
     * @dev Get the winning proposal(s) 
     * @return Array [Proposals] array of all winning proposal
     */
    function getWinner() external view returns (Proposal[] memory) {
        require(workflowStatus == WorkflowStatus.VotesTallied, 'Votes are not tallied yet');
        return winningProposals;
    }
 
    // ::::::::::::: REGISTRATION ::::::::::::: // 

    /**
     * @dev Register a voter
     * @dev only admin can make that transaction
     * @dev emit VoterRegistered event 
     * @param _addr {address} the voter's address
     */
    function addVoter(address _addr) public onlyOwner {
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
    /**
     * @dev Adding a proposal
     * @dev only voters can add proposals
     * @dev emit ProposalRegistered event 
     * @param _desc {string} the proposal's description
     */
    function addProposal(string memory _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        require(voters[msg.sender].proposedProposalCount <= 5, 'You can not create more than 5 proposals');
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        voters[msg.sender].proposedProposalCount++;
        emit ProposalRegistered(proposalsArray.length-1);
    }

    // ::::::::::::: VOTE ::::::::::::: //

    /**
    * @dev Vote for a proposal
    * @dev only voters can make that transaction
    * @dev emit Voted event 
    * @param _id {uint} Proposal's description
    */
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

    *  modifier checkWorkflowStatus(WorkflowStatus _num) {
    *  require (workflowStatus=_num-1, "bad workflowstatus");
    *  _;
    *  }

    *  function setWorkflowStatus(WorkflowStatus _num) public onlyOwner {
    *    WorkflowStatus pnum = workflowStatus;
    *    workflowStatus = _num;
    *    emit WorkflowStatusChange(pnum, workflowStatus);
        } */ 

    /**
    * @dev Start the proposal registering
    * @dev only admin can make the transaction
    * @dev emit WorkflowStatusChange event 
    */
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /**
    * @dev End the proposal registering
    * @dev only admin can make that transaction
    * @dev emit WorkflowStatusChange event 
    */
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /**
    * @dev Sàtart the voting session
    * @dev only admin can make that transaction
    * @dev emit WorkflowStatusChange event 
    */
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /**
    * @dev End the voting session
    * @dev only admin can make that transaction
    * @dev emit WorkflowStatusChange event 
    */
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /**
    * @dev Tally the votes
    * @dev only admin can make that transaction
    * @dev emit WorkflowStatusChange event 
    */
    function tallyVotesDraw() external onlyOwner {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
       require(proposalsArray.length < 12000, "Too many proposals, use emergencySpecificRangeTallyVotesDraw() instead (not implemented)");
       
        uint highestCount;
        uint[5]memory winners; // egalite entre 5 personnes max
        uint nbWinners;
        for (uint i = 0; i < proposalsArray.length; i++) {
            if (proposalsArray[i].voteCount == highestCount) {
                winners[nbWinners]=i;
                nbWinners++;
            }
            if (proposalsArray[i].voteCount > highestCount) {
                delete winners;
                winners[0]= i;
                highestCount = proposalsArray[i].voteCount;
                nbWinners=1;
            }
        }
        for(uint j=0;j<nbWinners;j++){
            winningProposalsID.push(winners[j]);
            winningProposals.push(proposalsArray[winners[j]]);
        }
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

   

  /*  function tallyVotes() external onlyOwner {
    *    require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
    *   uint _winningProposalId;
    *  for (uint256 p = 0; p < proposalsArray.length; p++) {
    *       if (proposalsArray[p].voteCount > proposalsArray[_winningProposalId].voteCount) {
    *           _winningProposalId = p;
    *      }
    *   }
    *   winningProposalID = _winningProposalId;
    *   
    *   workflowStatus = WorkflowStatus.VotesTallied;
    *   emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    *}
    */
}