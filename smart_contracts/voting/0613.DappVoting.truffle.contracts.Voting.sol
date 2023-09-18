// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title A voting system on the blockchain
 *
 * @author Jean-Baptiste Fund -> telegram : @theblockdev - email : frenchcryptoagency@gmail.com
 *
 * @notice This contract is a simplified voting system divided into four parts :<br>
 *
 * @dev First, the owner registers the participants<br>
 * @dev Second, voters can register proposals<br>
 * @dev Then, the voters vote for their favorite proposal<br>
 * @dev Finally, the owner tallies the votes. <br>
 *<br>
 * @dev To separate these different phases, we use the enum of the contract, only the owner can change the enum. <br>
 *
 * @dev WARNING : In order to avoid a DOS flaw, we have added a proposal limit. Make sure that this limit matches the use you want to make with this voting system. 
 */

contract Voting is Ownable {

/**
 * @dev winningProposalID is the winning proposal of the vote 
 */
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

/**
 * @dev workflowStatus is the status of voting 
 */
    WorkflowStatus public workflowStatus;
    Proposal[] proposalsArray;
    mapping (address => Voter) voters;

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId, string description);
    event Voted (address voter, uint proposalId);

    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }
    
/**
 * @dev Only voters can call getVoter
 * @param _addr is the address of the voter
 * @return voters is the struct of the voter
 */

    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
/**
 * @dev Only voters can call getOneProposal
 * @param _id is the id of the proposal
 * @return proposalsArray is the struct of the proposal
 */    
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

/**
 * @dev Only owner can add a voter
 * @param _addr is the address of the voter
 */

    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 
/**
 * @dev Only voters can add a proposal <br> Warning before deploy, check the limit of proposalsArray.length
 * @param _desc is the description of the proposal
 */    

    function addProposal(string memory _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer');
        require(proposalsArray.length<100, "Proposal's Array is complete");

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length-1, _desc);
    }

/**
 * @dev Only voters can set a vote
 * @param _id is the id of the proposal
 */ 

    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found');

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        emit Voted(msg.sender, _id);
    }

/**
 * @dev Only owner can change the state
 */    

    function changeState() external onlyOwner {                                
        if (workflowStatus==WorkflowStatus.VotesTallied){
            workflowStatus=WorkflowStatus(0);
        }
        else workflowStatus=WorkflowStatus(uint(workflowStatus)+1);   
    
        if (workflowStatus==WorkflowStatus.RegisteringVoters) {               
            emit WorkflowStatusChange(WorkflowStatus(5),WorkflowStatus(0));
        }
        else {
            emit WorkflowStatusChange(WorkflowStatus (uint (workflowStatus)-1), WorkflowStatus(uint(workflowStatus)));
            }
    }

/**
 * @dev Only owner can tally the votes
 */

   function tallyVotes() external onlyOwner {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
       uint _winningProposalId;
      for (uint256 p = 0; p < proposalsArray.length; p++) {
           if (proposalsArray[p].voteCount > proposalsArray[_winningProposalId].voteCount) {
               _winningProposalId = p;
          }
       }
       winningProposalID = _winningProposalId;
    }
}