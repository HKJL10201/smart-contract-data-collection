// SPDX-License-Identifier:  GPL-3.0
pragma solidity >=0.4.21 <=0.8;
 
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Voting
 * @dev Organise Voters registration, proposals registration, votes talling, resetting session
 * @author Hélène Bunel
 * @author Edouard Vahanian
 * @author Daniel Villa Monteiro
 * @notice We use uint16 size to index propoesals, voters and sessions (limit 65 536)
 */

contract Voting is Ownable {
    
    /**
     * @dev Structure of Voter
     * @notice Feature_V2 : isAbleToPropose and hasProposed
     */
    struct Voter {
        bool isRegistered;
        bool hasVoted; 
        uint16 votedProposalId;
        bool isAbleToPropose; 
        bool hasProposed; 
    }
    
     /**
     * @dev Structure of Voter
     * @notice Feature_V2 : author and isActive
     */
    struct Proposal {
        string description;
        uint16 voteCount;
        address author; 
        bool isActive;   
    }
    
    /**
     * @dev Structure of Session
     * @notice Feature_V2
     */
    struct Session {
        uint startTimeSession;  
        uint endTimeSession;  
        string winningProposalName;    
        address proposer;
        uint16 nbVotes;
        uint16 totalVotes;
    }


    /**
     * @dev WorkflowStatus
     * @notice 6 states 
     */
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
 
    event VoterRegistered(address voterAddress, bool isAbleToPropose, uint sessionId);
    event VoterUnRegistered(address voterAddress, uint sessionId);                                              // Feature_V2     
    event ProposalsRegistrationStarted(uint sessionId);
    event ProposalsRegistrationEnded(uint sessionId);
    event ProposalRegistered(uint proposalId, string proposal, address author, uint sessionId);
    event ProposalUnRegistered(uint proposalId, string proposal, address author, uint sessionId);                                                // Feature_V2    
    event VotingSessionStarted(uint sessionId);
    event VotingSessionEnded(uint sessionId);
    event Voted (address voter, uint proposalId, uint sessionId);
    event VotesTallied(uint sessionId);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus, uint sessionId);
    event SessionRestart(uint sessionId);
    
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    Session[] public sessions;
    address[] public addressToSave;
    uint16 proposalWinningId;
    uint16 public sessionId;    
    
    WorkflowStatus public currentStatus;

    constructor () public{
        sessionId=0;
        sessions.push(Session(0,0,'NC',address(0),0,0));
        currentStatus = WorkflowStatus.RegisteringVoters;
        proposals.push(Proposal('Vote blanc', 0, address(0), true));
        emit ProposalRegistered(0, 'Vote blanc', address(0),sessionId);            
    }

    /**
     * @dev Add a voter
     * @param _addressVoter address of new voter
     * @param _isAbleToPropose is voter abble to propose proposals
     */
    function addVoter(address _addressVoter, bool _isAbleToPropose) external onlyOwner{
        require(currentStatus == WorkflowStatus.RegisteringVoters, "Not RegisteringVoters Status");        
        require(!voters[_addressVoter].isRegistered, "Voter already registered");

        voters[_addressVoter] = Voter(true, false, 0, _isAbleToPropose, false);
        addressToSave.push(_addressVoter);

        emit VoterRegistered(_addressVoter, _isAbleToPropose, sessionId);
    }
    
    /**
     * @dev Remove a voter
     * @param _addressVoter address of new voter
     */
    function removeVoter(address _addressVoter) external onlyOwner{
        require(currentStatus == WorkflowStatus.RegisteringVoters, "Not RegisteringVoters Status");        
        require(voters[_addressVoter].isRegistered, "Voter not registered");
        
        voters[_addressVoter].isRegistered = false;

        emit VoterUnRegistered(_addressVoter, sessionId);
    }

    /**
     * @dev Change status to ProposalsRegistrationStarted
     */
    function proposalSessionBegin() external onlyOwner{
        require(currentStatus == WorkflowStatus.RegisteringVoters, "Not RegisteringVoters Status");
        
        sessions[sessionId].startTimeSession = block.timestamp;
        
        currentStatus = WorkflowStatus.ProposalsRegistrationStarted;

        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted, sessionId);
        emit ProposalsRegistrationStarted(sessionId);       
    }

    /**
     * @dev Add a proposal
     * @param _content content of proposal
     */
    function addProposal(string memory _content) external {
        require(currentStatus == WorkflowStatus.ProposalsRegistrationStarted, "Not ProposalsRegistrationStarted Status");
        require(voters[msg.sender].isRegistered, "Voter not registered");
        require(voters[msg.sender].isAbleToPropose, "Voter not proposer");
        require(!voters[msg.sender].hasProposed, "Voter has already proposed");

        proposals.push(Proposal(_content, 0, msg.sender, true));
        voters[msg.sender].hasProposed = true;
        
        uint proposalId = proposals.length-1;

        emit ProposalRegistered(proposalId, _content, msg.sender, sessionId);
    }    

    /**
     * @dev Change status to ProposalsRegistrationEnded
     */
    function proposalSessionEnded() external onlyOwner{
        require(currentStatus == WorkflowStatus.ProposalsRegistrationStarted, "Not ProposalsRegistrationStarted Status");
        
        currentStatus = WorkflowStatus.ProposalsRegistrationEnded;
        
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded, sessionId);
        emit ProposalsRegistrationEnded(sessionId);       
    }
    
    /**
     * @dev Remove a proposal
     * @param _proposalId index of proposal to deactivate
     * @notice Feature_V2
     */
    function removeProposal(uint16 _proposalId) external onlyOwner{
        require(currentStatus == WorkflowStatus.ProposalsRegistrationEnded, "Not ProposalsRegistrationEnded Status");
      
        proposals[_proposalId].isActive = false;

        emit ProposalUnRegistered(_proposalId, proposals[_proposalId].description, proposals[_proposalId].author, sessionId);
    }        
    
    /**
     * @dev Change status to VotingSessionStarted
     */
    function votingSessionStarted() external onlyOwner{
        require(currentStatus == WorkflowStatus.ProposalsRegistrationEnded, "Not ProposalsRegistrationEnded Status");
        
        currentStatus = WorkflowStatus.VotingSessionStarted;
        
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted, sessionId);
        emit VotingSessionStarted(sessionId);        
    }    
    
    /**
     * @dev Add a vote
     * @param _votedProposalId index of proposal to vote
     */
    function addVote(uint16 _votedProposalId) external {
        require(currentStatus == WorkflowStatus.VotingSessionStarted, "It is not time to vote!");        
        require(voters[msg.sender].isRegistered, "Voter can not vote");
        require(!voters[msg.sender].hasVoted, "Voter has already vote");        
        require(proposals[_votedProposalId].isActive, "Proposition inactive");      

        voters[msg.sender].votedProposalId = _votedProposalId;
        voters[msg.sender].hasVoted = true;
        proposals[_votedProposalId].voteCount++;

        emit Voted (msg.sender, _votedProposalId, sessionId);
    }
    
     /**
     * @dev Change status to VotingSessionEnded
     */ 
    function votingSessionEnded() external onlyOwner{
        require(currentStatus == WorkflowStatus.VotingSessionStarted, "Not VotingSessionStarted Status");
        
        currentStatus = WorkflowStatus.VotingSessionEnded;
        
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded, sessionId);
        emit VotingSessionEnded(sessionId);     
    }       
      
    /**
     * @dev Tallied votes
     */
    function votesTallied() external onlyOwner {
        require(currentStatus == WorkflowStatus.VotingSessionEnded, "Session is still ongoing");
        
        uint16 currentWinnerId;
        uint16 nbVotesWinner;
        uint16 totalVotes;

        currentStatus = WorkflowStatus.VotesTallied;

        for(uint16 i; i<proposals.length; i++){
            if (proposals[i].voteCount > nbVotesWinner){
                currentWinnerId = i;
                nbVotesWinner = proposals[i].voteCount;
            }
            totalVotes += proposals[i].voteCount;
        }
        proposalWinningId = currentWinnerId;
        sessions[sessionId].endTimeSession = block.timestamp;
        sessions[sessionId].winningProposalName = proposals[currentWinnerId].description;
        sessions[sessionId].proposer = proposals[currentWinnerId].author;
        sessions[sessionId].nbVotes = nbVotesWinner;
        sessions[sessionId].totalVotes = totalVotes;       

        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied, sessionId);
        emit VotesTallied(sessionId);
    }

    /**
     * @dev Send Winning Proposal
     * @return contentProposal description of proposal
     * @return nbVotes number of votes
     * @return nbVotesTotal number of totals votes
     */
    function getWinningProposal() external view returns(string memory contentProposal, uint16 nbVotes, uint16 nbVotesTotal){
        require(currentStatus == WorkflowStatus.VotesTallied, "Tallied not finished"); 
        return (
            proposals[proposalWinningId].description,
            proposals[proposalWinningId].voteCount,
            sessions[sessionId].totalVotes
        );
    }

    /**
     * @dev Send Session
     * @param _sessionId index of session     
     * @return winningProposalName description of proposal
     * @return proposer author of proposal     
     * @return nbVotes number of votes
     * @return totalVotes number of totals votes
     */
    function getSessionResult(uint16 _sessionId) external view returns(string memory winningProposalName, address proposer, uint16 nbVotes, uint16 totalVotes){
        require(sessionId >= _sessionId, "Session not exist"); 
        return (
            sessions[_sessionId].winningProposalName,
            sessions[_sessionId].proposer,
            sessions[_sessionId].nbVotes,
            sessions[_sessionId].totalVotes
        );
    }
    
    /**
     * @dev Restart session
     * @param deleteVoters delete voters
     * @notice Feature_V2  
     */ 
    function restartSession (bool deleteVoters) external onlyOwner{
        require(currentStatus == WorkflowStatus.VotesTallied, "Tallied not finished"); 
  
        delete(proposals);
        
        if(deleteVoters){
            for(uint16 i; i<addressToSave.length; i++){
                delete(voters[addressToSave[i]]);
            }
            delete(addressToSave);
        }
        else{
            for(uint16 i; i<addressToSave.length; i++){
                voters[addressToSave[i]].hasVoted=false;
                voters[addressToSave[i]].hasProposed=false;   
                if(voters[addressToSave[i]].isRegistered){
                    emit VoterRegistered(addressToSave[i], voters[addressToSave[i]].isAbleToPropose, sessionId+1);
                }      
            }
        }    
    
        sessionId++;
        sessions.push(Session(0,0,'NC',address(0),0,0));
        currentStatus = WorkflowStatus.RegisteringVoters;
        proposals.push(Proposal('Vote blanc', 0, address(0), true));      

        emit SessionRestart(sessionId);
        emit ProposalRegistered(0, 'Vote blanc', address(0), sessionId);    
    }
} 