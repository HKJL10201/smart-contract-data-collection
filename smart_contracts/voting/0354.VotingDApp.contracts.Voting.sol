// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Ownable.sol";

contract Voting is Ownable {
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint proposalsCount;
        uint votedProposalId;
    }
    
    struct Proposal {
        string description;
        uint voteCount;
    }
    
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    address[] public whitelist;
    Proposal[] public proposals;
    uint public winningProposalId;
    mapping (address => Voter) public voters;
    WorkflowStatus public voteStatus;
    
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event Voted (address voter, uint proposalId);
    event VotingSessionEnded();
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    /** @dev Return a list with all allowed address */
    function getWhitelist() external view returns(address[] memory) {
        return whitelist;
    }
    
    /** @dev Return a list of proposals */
    function getProposals() external view returns(Proposal[] memory) {
        return proposals;
    }
    
    /** @dev The administrator registers a voters of voters identified by their Ethereum address.
     *  @param _address voter's ethereum address.
     *  ER1 : The vote has already started.
     *  ER2 : The voter already exist.
     */ 
    function addToWhitelist(address _address) external onlyOwner {
        require(voteStatus == WorkflowStatus.RegisteringVoters, "ER1");
        require(!voters[_address].isRegistered, "ER2");
        voters[_address].isRegistered = true;
        whitelist.push(_address);

        emit VoterRegistered(_address);
    }
    
    /** @dev The administrator starts the proposal registration session.
     *  ER1 : The vote has already started.
     */ 
    function proposalsRegistrationStart() external onlyOwner {
        require(voteStatus == WorkflowStatus.RegisteringVoters, "ER1");
        voteStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
        emit ProposalsRegistrationStarted();
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }
    
    /** @dev Registered voters are allowed to register their proposals while the registration session is active.
     *  @param _description Content of the proposal.
     *  ER3 : You're not allowed to vote.
     *  ER4 : Registration has not yet started or is already ended.
     *  ER5 : The number of proposals per voter is limited to 100.
     */
    function proposalsRegistration(string memory _description) external {
        require(voters[msg.sender].isRegistered, "ER3");
        require(voteStatus == WorkflowStatus.ProposalsRegistrationStarted, "ER4");
        require(voters[msg.sender].proposalsCount <= 99, "ER5");
        voters[msg.sender].proposalsCount ++;
        proposals.push(Proposal(_description, 0));
        
        emit ProposalRegistered(proposals.length-1);
    }
    
    /** @dev The administrator closes the proposal registration session.
     *  ER6 : Registration has to be started
     */
    function proposalsRegistrationEnd() external onlyOwner {
        require(voteStatus == WorkflowStatus.ProposalsRegistrationStarted, "ER6");
        voteStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit ProposalsRegistrationEnded();
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }
    
    /** @dev Administrator starts the voting session.
     *  ER7 : Registration has to be ended.
     */
    function votingSessionStart() external onlyOwner {
        require(voteStatus == WorkflowStatus.ProposalsRegistrationEnded, "ER7");
        voteStatus = WorkflowStatus.VotingSessionStarted;
        emit VotingSessionStarted();
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }
    
    /** @dev Registered voters vote for their preferred proposals.
     *  @param proposalId Number of the voter's preferred proposal.
     *  ER3 : You're not allowed to vote.
     *  ER8 : You have already voted.
     *  ER9 : Non-existent proposal.
     *  ER10 : The voting session has to be started.
     */
    function vote(uint proposalId) external {
        require(voters[msg.sender].isRegistered, "ER3");
        require(!voters[msg.sender].hasVoted, "ER8");
        require(proposalId <= proposals.length - 1, "ER9");
        require(voteStatus == WorkflowStatus.VotingSessionStarted, "ER10");
        
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = proposalId;
        proposals[proposalId].voteCount ++;
        
        // Other method to count the vote
        // if (proposals[proposalId].voteCount > proposals[winningProposalId].voteCount) {
        //     winningProposalId = proposalId;
        // }
        
        emit Voted(msg.sender, proposalId);
    }
    
    /** @dev The administrator ends the voting session.
     *  ER10 : The voting session has to be started.
     */
    function votingSessionEnd() external onlyOwner {
        require(voteStatus == WorkflowStatus.VotingSessionStarted, "ER10");
        voteStatus = WorkflowStatus.VotingSessionEnded;
        emit VotingSessionEnded();
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted , WorkflowStatus.VotingSessionEnded);
    }
    
    /** @dev The administrator counts the votes.
     *  ER11 : The voting session has to be ended.
     */
    function votesTally() external onlyOwner {
        require(voteStatus == WorkflowStatus.VotingSessionEnded, "ER11");
        uint _count;
        uint _tempWinner;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > _count) {
                _count = proposals[i].voteCount;
                _tempWinner = i;
            }
            
        }
        winningProposalId = _tempWinner;
        voteStatus = WorkflowStatus.VotesTallied;
        emit VotesTallied();
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded , WorkflowStatus.VotesTallied);
    }
}