// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable{

    struct Proposal {
        string name;
        uint voteCount;
    }

    struct Voter {
        uint voterId;
        uint votedProposalId;
        bool isRegistered;
        bool hasVoted;
    }

    enum ProcessStatus {
        RegisteringVotersStarted,
        RegisteringVotersEnded,
        ProposalRegistrationStarted,
        ProposalRegistrationEnded,
        VotingStarted,
        VotingEnded,
        VotesTallied
    }

    address public administrator;
    mapping (address => Voter) public voters;
    address[] private voterList;
    Proposal[] public proposals;
    ProcessStatus public processStatus;
    uint private winningProposalId;

    event VoterRegisteredEvent (address voterAddress); 
    event VotersRegistrationEndedEvent ();
    event ProposalsRegistrationStartedEvent ();
    event ProposalsRegistrationEndedEvent ();
    event ProposalRegisteredEvent(uint proposalId);
    event VotingSessionStartedEvent ();
    event VotingSessionEndedEvent ();
    event VotedEvent (address voter, uint proposalId);
    event VotesTalliedEvent ();

    event WorkflowStatusChangeEvent (
        ProcessStatus previousStatus, 
        ProcessStatus newStatus
    );
    constructor () {
        processStatus = ProcessStatus.RegisteringVotersStarted;
    }

    modifier isRegistered(address _address) {
        require(voters[_address].isRegistered, "Voter not registered!!!");
        _;
    }

    modifier onlyDuringVotersRegistration() {
        require(processStatus == ProcessStatus.RegisteringVotersStarted, "Process must be in voters registration phase!!!");
        _;
    }

    modifier isRegisteringProposals() {
        require(processStatus == ProcessStatus.ProposalRegistrationStarted, "Process must be in proposals registration phase!!!");
        _;
    }

    modifier isRegisteringProposalsEnded() {
        require(processStatus == ProcessStatus.ProposalRegistrationEnded, "Proposals registration must be finished!!!");
        _;
    }

    modifier isRegisteringVotes() {
        require(processStatus == ProcessStatus.VotingStarted, "Process must be in voting registration phase!!!");
        _;
    }

    modifier isRegisteringVotesEnded() {
        require(processStatus == ProcessStatus.VotingEnded, "Voting registration phase must be ended!!!");
        _;
    }

    function addVoter(address _address) public onlyOwner onlyDuringVotersRegistration {
        require(!voters[_address].isRegistered, "Voter already registered!!!");
        voters[_address].voterId = voterList.length;
        voters[_address].isRegistered = true;
        voters[_address].hasVoted = false;
        voters[_address].votedProposalId = 0;
        voterList.push(_address);

        emit VoterRegisteredEvent(_address);
    }

    function getVoterList() public view onlyOwner returns (address[] memory){
        return voterList;
    }

    function removeVoter(address _address) public onlyOwner onlyDuringVotersRegistration isRegistered(_address) {
        voters[_address].isRegistered = false;
        voters[_address].hasVoted = false;
        voters[_address].votedProposalId = 0;
    }

    function endVotersRegistration() public onlyOwner onlyDuringVotersRegistration {
        processStatus = ProcessStatus.RegisteringVotersEnded;

        emit VotersRegistrationEndedEvent();

    }

    function startProposalRegistration() public onlyOwner returns(ProcessStatus){
        processStatus = ProcessStatus.ProposalRegistrationStarted;

        emit ProposalsRegistrationStartedEvent ();
        return processStatus;

    }

    function addProposal(string memory _name) public isRegisteringProposals {
        proposals.push(Proposal(_name, 0));

        emit ProposalRegisteredEvent(proposals.length - 1 );

    }

    function getProposalList() public view returns (Proposal[] memory){
        return proposals;
    }

    function endProposalRegistration() public onlyOwner isRegisteringProposals returns(ProcessStatus){
        processStatus = ProcessStatus.ProposalRegistrationEnded;
        emit ProposalsRegistrationEndedEvent ();

        return processStatus;

    }

    function startVotesRegistration() public onlyOwner isRegisteringProposalsEnded returns (ProcessStatus){
        processStatus = ProcessStatus.VotingStarted;

        emit VotingSessionStartedEvent ();

        return processStatus;

    }

    function addVote(uint _proposalId) public isRegisteringVotes isRegistered(msg.sender) {
        require(!voters[msg.sender].hasVoted, "Participants can vote just one time!!");
        proposals[_proposalId].voteCount++;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;

        emit VotedEvent (msg.sender, _proposalId);


    }

    function endVotesRegistration() public onlyOwner isRegisteringVotes returns (ProcessStatus) {
        processStatus = ProcessStatus.VotingEnded;
        
        emit VotingSessionEndedEvent ();
        return processStatus;
    }

    function tallyVotes() public onlyOwner isRegisteringVotesEnded {
        require(proposals.length > 0, "Empty proposals array!!!");

        uint i = 0;
        uint winningProposalIndex = 0;
        uint winningVoteCount = 0;

        for(i=0; i<=proposals.length-1; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalIndex = i;
            }
        }

        winningProposalId = winningProposalIndex;
        processStatus = ProcessStatus.VotesTallied;
    }

}