//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract VotingSystem {

    address manager;

    enum VotingSteps {REGISTER, VOTE, END}

    VotingSteps public votingStep;

    struct Candidate {
        string name;
        address candidateAddress;
        int id; 
        int voteNumber;
    }

    struct Voter {
        string fiscalCode;
        int id;
        bool hasVoted;
    }

    mapping(address => Candidate) public candidate;

    mapping(address => Voter) public voter;

    int voterId = 0;

    int candidateId = 0;

    constructor() {
        manager = msg.sender;
        votingStep = VotingSteps.REGISTER;
    }

    modifier onlyOwner() {
        assert(msg.sender == manager);
        _;
    }

    modifier registeringPhase() {
        assert(votingStep == VotingSteps.REGISTER);
        _;
    }

    modifier votingPhase(){
        assert(votingStep == VotingSteps.VOTE);
        _;
    }

    modifier endPhase(){
        assert(votingStep == VotingSteps.END);
        _;
    }

    function enterVotingPhase() public onlyOwner registeringPhase{
        votingStep = VotingSteps.VOTE;
    }

     function enterResultPhase() public onlyOwner votingPhase{
        votingStep = VotingSteps.END;
    }

    function registerVoter(string memory _fiscalCode, address _address) public registeringPhase{
        Voter memory newVoter = Voter(_fiscalCode, voterId, false);
        voterId += 1;
        voter[_address] = newVoter;
    }

    function registerCandidate(string memory _name, address _candidateAddress) public registeringPhase{
        Candidate memory newCandidate = Candidate(_name, _candidateAddress, candidateId, 0);
        candidate[_candidateAddress] = newCandidate;
        candidateId += 1;
    }

    function voteCandidate(address _address) public votingPhase{
        assert(voter[msg.sender].hasVoted == false);
        candidate[_address].voteNumber += 1;
        voter[msg.sender].hasVoted = true;
    }
}