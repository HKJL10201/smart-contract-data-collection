// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Voting
 * @author Fabien COUTANT
 * @dev Implements a voting system where users are imported by admin
 *
 */
contract Voting is Ownable {

    //Structure
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    //Enum
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }


    //Var
    uint private winningProposalId;

    Proposal[] private proposalList;
    mapping(string=>bool) private existingProposal;

    WorkflowStatus private status = WorkflowStatus.RegisteringVoters;

    //mapping
    mapping(address=>Voter) private whitelist;
    address[] private listOfWhitelisted;

    //Events
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus
    newStatus);

    //modifier
    modifier checkStatus(WorkflowStatus _currentStatus, WorkflowStatus _expectedStatus){
        require(_currentStatus==_expectedStatus,"Current workflow status not align with expectation");
        _;
    }

    modifier onlyWhitelistedUser(){
        require(whitelist[msg.sender].isRegistered,"You are not whitelisted");
        _;
    }

    /**
     * @dev Change the WorkflowStatus to the next one
     * @return Whether or not the workflow status change succeeded
     */
    function nextWorkflowStatus() public onlyOwner returns(bool){
        require(status<WorkflowStatus.VotingSessionEnded,"You can't go forwards");
        WorkflowStatus _previousStatus = status;
        status=WorkflowStatus(uint(status) + 1);
        if(uint(status)==1){
            emit ProposalsRegistrationStarted();
        }else if(uint(status)==2){
            emit ProposalsRegistrationEnded();
        }else if(uint(status)==3){
            emit VotingSessionStarted();
        }else if(uint(status)==4){
            emit VotingSessionEnded();
        }
        emit WorkflowStatusChange(_previousStatus, status);
        return true;
    }

    /**
     * @dev Add new voter to the whitelisted
     * @param _voter address of the new voter
     * @return Whether or not adding new Voter succeeded
     */
    function addNewVoter(address _voter) external onlyOwner checkStatus(status,WorkflowStatus.RegisteringVoters) returns(bool){
        require(!whitelist[_voter].isRegistered,"Voter already register");
        whitelist[_voter]=Voter(true, false,0);
        listOfWhitelisted.push(_voter);
        emit VoterRegistered(_voter);
        return true;
    }

    /**
     * @dev Allow whitelisted user to add proposal if status is at ProposalsRegistrationStarted
     * @param _description string of the user proposal
     * @return Whether or not adding new Proposal succeeded
     */
    function addProposal(string calldata _description) external onlyWhitelistedUser checkStatus(status,WorkflowStatus.ProposalsRegistrationStarted) returns(bool){
        require(!existingProposal[_description],"This proposal already exist");
        proposalList.push(Proposal(_description,0));
        existingProposal[_description]=true;
        emit ProposalRegistered(getNumberOfProposals()-1);
        return true;
    }


    /**
     * @dev Allow whitelisted user to add vote one time for a proposal
     * @param _proposalId uint of the proposal id number
     * @return Whether or not adding new Proposal succeeded
     */
    function addVote(uint _proposalId) external checkStatus(status,WorkflowStatus.VotingSessionStarted) onlyWhitelistedUser returns(bool){
        require(_proposalId<=getNumberOfProposals()-1,"The proposalId is out of the array");
        require(!whitelist[msg.sender].hasVoted,"You have already voted");
        proposalList[_proposalId].voteCount++;
        if(proposalList[_proposalId].voteCount > proposalList[winningProposalId].voteCount){
            winningProposalId = _proposalId;
        }
        (whitelist[msg.sender].hasVoted,whitelist[msg.sender].votedProposalId)=(true,_proposalId);
        emit Voted(msg.sender, _proposalId);
        return true;
    }

    /**
     * @dev Allow admin to select the winning proposal
     * @return Whether or not calling the result succeeded
     */
    function results() external onlyOwner checkStatus(status,WorkflowStatus.VotingSessionEnded) returns(bool){
        status = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            status
        );
        emit VotesTallied();
        return true;
    }


    /**
     * @dev Getter of proposal information
     * @param _proposalId uint of the proposal id number
     * @return Proposal
     */
    function getProposalById(uint _proposalId) external view returns(Proposal memory){
        return proposalList[_proposalId];
    }

    /**
     * @dev Get the proposals list
     * @return Proposal[]
     */
    function getProposals() external view returns(Proposal[] memory){
        return proposalList;
    }

    /**
     * @dev Get the list of whitelisted address
     * @return listOfWhitelisted[]
     */
    function getListOfWhitelist() external view returns(address[] memory){
        return listOfWhitelisted;
    }
    /**
     * @dev Getter of whitelisted user information
     * @param _voterAddress address of the whitelisted user
     * @return Voter memory
     */
    function getVoterInfoByAddress(address _voterAddress) external view returns(Voter memory){
        return whitelist[_voterAddress];
    }

    /**
     * @dev Getter of current workflow status
     * @return WorkflowStatus number
     */
    function getCurrentStatus() external view returns(WorkflowStatus){
        return status;
    }


    /**
     * @dev Getter of winning proposalId
     * @return proposalId uint
     */
    function getWinningProposalId() external view checkStatus(status,WorkflowStatus.VotesTallied) returns(uint proposalId){
        return winningProposalId;
    }


    /**
     * @dev Return the number of proposal
     * @return uint number of total proposal registered
     */
    function getNumberOfProposals() private returns(uint){
        return proposalList.length;
    }
}
