pragma solidity ^0.4.22;

contract SimpleVoting {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
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


    address public administrator;
    mapping (address => Voter) public voters;
    Proposal[] public proposals;
    uint private winningProposalId;
    WorkflowStatus public workflowStatus;


    modifier onlyAdministrator() {
        require(msg.sender == administrator,
            "the caller of this function must be the administrator");
        _;
    }
    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].isRegistered,
            "the caller of this function must be a registered voter");
        _;
    }

    modifier onlyDuringVotersRegistration() {
        require(workflowStatus == WorkflowStatus.RegisteringVoters,
            "this function can be called only during voters registration");
        _;
    }
    modifier onlyDuringProposalsRegistration() {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "this function can be called only during proposals registration");
        _;
    }
    modifier onlyAfterProposalsRegistration() {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded,
            "this function can be called only after proposals registration has ended");
        _;
    }
    modifier onlyDuringVotingSession() {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted,
            "this function can be called only during voting session");
        _;
    }
    modifier onlyAfterVotingSession() {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded,
            "this function can be called only after voting session has ended");
        _;
    }
    modifier onlyAfterVotesTallied() {
        require(workflowStatus == WorkflowStatus.VotesTallied,
            "this function can be called only after votes have been tallied");
        _;
    }


    event VoterRegisteredEvent (address voterAddress);

    event ProposalsRegistrationStartedEvent ();
    event ProposalsRegistrationEndedEvent ();
    event ProposalRegisteredEvent (uint proposalId);

    event VotingSessionStartedEvent ();
    event VotingSessionEndedEvent ();
    event VotedEvent (address voter, uint proposalId);
    
    event VotesTalliedEvent ();

    event WorkflowStatusChangedEvent (WorkflowStatus previousStatus, WorkflowStatus newStatus);


    constructor() public {
        administrator = msg.sender;
        workflowStatus = WorkflowStatus.RegisteringVoters;
    }

    function isAdministrator(address _address)
        public view returns (bool) {
        
        return _address == administrator;
    }
    function isRegisteredVoter(address _address)
        public view returns (bool) {

        return voters[_address].isRegistered;
    }

    function registerVoter(address _voterAddress)
        public onlyAdministrator onlyDuringVotersRegistration {
        
        require(!voters[_voterAddress].isRegistered,
            "the voter is already registered");
        
        voters[_voterAddress].isRegistered = true;
        voters[_voterAddress].hasVoted = false;
        voters[_voterAddress].votedProposalId = 0;

        emit VoterRegisteredEvent(_voterAddress);
    }

    function startProposalsRegistration()
        public onlyAdministrator onlyDuringVotersRegistration {
        
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;

        emit ProposalsRegistrationStartedEvent();
        emit WorkflowStatusChangedEvent(
            WorkflowStatus.RegisteringVoters,
            workflowStatus
        );
    }
    function endProposalsRegistration()
        public onlyAdministrator onlyDuringProposalsRegistration {
        
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;

        emit ProposalsRegistrationEndedEvent();
        emit WorkflowStatusChangedEvent(
            WorkflowStatus.ProposalsRegistrationStarted,
            workflowStatus
        );
    }
    function registerProposal(string _proposalDescription)
        public onlyRegisteredVoter onlyDuringProposalsRegistration {
        
        proposals.push(
            Proposal({
                description : _proposalDescription,
                voteCount : 0
            })
        );

        emit ProposalRegisteredEvent(proposals.length - 1);
    }

    function getProposalsNumber() public view returns (uint) {
        return proposals.length;
    }
    function getProposalDescription(uint _index) public view
        returns (string) {
        return proposals[_index].description;
    }

    function startVotingSession()
        public onlyAdministrator onlyAfterProposalsRegistration {
        
        workflowStatus = WorkflowStatus.VotingSessionStarted;

        emit VotingSessionStartedEvent();
        emit WorkflowStatusChangedEvent(
            WorkflowStatus.ProposalsRegistrationEnded,
            workflowStatus
        );
    }
    function endVotingSession()
        public onlyAdministrator onlyDuringVotingSession {
        
        workflowStatus = WorkflowStatus.VotingSessionEnded;

        emit VotingSessionEndedEvent();
        emit WorkflowStatusChangedEvent(
            WorkflowStatus.VotingSessionStarted,
            workflowStatus
        );
    }
    function vote(uint _proposalId)
        public onlyRegisteredVoter onlyDuringVotingSession {
        
        require(!voters[msg.sender].hasVoted,
            "the caller has already voted");
        
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;

        proposals[_proposalId].voteCount += 1;

        emit VotedEvent(msg.sender, _proposalId);
    }

    function tallyVotes()
        public onlyAdministrator onlyAfterVotingSession {

        uint winningVoteCount = 0;
        uint winningProposalIndex = 0;

        for (uint i=0; i<proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalIndex = i;
            }
        }

        winningProposalId = winningProposalIndex;
        workflowStatus = WorkflowStatus.VotesTallied;

        emit VotesTalliedEvent();
        emit WorkflowStatusChangedEvent(
            WorkflowStatus.VotingSessionEnded,
            workflowStatus
        );
    }

    function getWinningProposalId()
        public view onlyAfterVotesTallied returns (uint) {
        
        return winningProposalId;
    }
    function getWinningProposalDescription()
        public view onlyAfterVotesTallied returns (string) {

        return proposals[winningProposalId].description;        
    }
    function getWinningProposalVoteCount()
        public view onlyAfterVotesTallied returns (uint) {
        
        return proposals[winningProposalId].voteCount;
    }
    
    function getWorkflowStatus() public view returns (WorkflowStatus) {
        return workflowStatus;
    }
}