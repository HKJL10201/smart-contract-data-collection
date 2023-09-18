// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract VotingContract { 

    mapping(string => Voting) public votings;

    struct Voting {
        VotingState votingState;
        mapping(address => Candidate) candidates;
        address[] candidatesAddresses;
        mapping (address => Voter) voters;
        uint votingBalance;
        bool withDrawOccured;
        uint256 startDate;
        Candidate winnerCandidate;
    }

    struct Voter {
        string voterName;
        bool voted;
    }

    struct Candidate {
        address candidateAddress; 
        uint voteCount; 
    }

    enum VotingState { NotCreated, InProgress, Ended }

    address payable public contractOwner;
    
    constructor() {
        contractOwner = payable(msg.sender);
    }

    function createVote(string calldata voteName, address[] calldata candidateAddresses, uint256 startDate)
        external
    {   
        require(msg.sender == contractOwner, "Only contractOwner can start and end the voting");

        Voting storage voting = votings[voteName];
        voting.votingState = VotingState.InProgress;
        voting.votingBalance = 0;
        voting.withDrawOccured = false;
        voting.startDate = startDate;

        mapping(address => Candidate) storage candidates = voting.candidates;
        address[] storage candidatesAddresses = voting.candidatesAddresses;
        for (uint i = 0; i < candidateAddresses.length; i++){
            address candidateAddress = candidateAddresses[i];
            Candidate memory candidate = Candidate({
                candidateAddress: candidateAddress,
                voteCount: 0
            });
            candidates[candidateAddress] = candidate;
            candidatesAddresses.push(candidate.candidateAddress);
        }
    }

    function vote(string calldata voteName, address candidateAddress) 
        external 
        payable  
    {
        Voting storage voting = votings[voteName];

        require(msg.value == 0.01 ether, "Your payment should be equal to 10000000000000000 wei");
        require(voting.voters[msg.sender].voted == false, "You already voted");

        voting.votingBalance = voting.votingBalance + msg.value;
        Candidate storage candidate = voting.candidates[candidateAddress];
        candidate.voteCount += 1;
        voting.voters[msg.sender].voted = true;
    }

    function endVote(string calldata votingName)
        external
        payable
    {
        require(votings[votingName].votingState == VotingState.InProgress, "It must be in InProgress votingState");
        require(block.timestamp >= votings[votingName].startDate + 3 minutes, "You can end voting only after 3 minutes");

        Voting storage voting = votings[votingName];
        voting.votingState = VotingState.Ended;
        Candidate memory winnerCandidate = this.getWinnerCandidate(votingName);
        voting.winnerCandidate = winnerCandidate;
        address payable winnerAddress = payable(winnerCandidate.candidateAddress);
        uint winnerAmount = (voting.votingBalance / 10) * 9;
        winnerAddress.transfer(winnerAmount);
    }

    function widthdraw(string calldata voteName, address payable withdrawAddress) 
        external 
        payable
    {
        require(msg.sender == contractOwner, "Only contractOwner can start and end the voting");
        require(votings[voteName].votingState == VotingState.Ended, "It must be in Ended votingState");
        require(votings[voteName].withDrawOccured == false, "Withdraw for this voting has already been made");

        Voting storage voting = votings[voteName];

        uint votingBalance = voting.votingBalance;
        uint widthdrawAmount = votingBalance / 10;
        withdrawAddress.transfer(widthdrawAmount);
        voting.withDrawOccured = true;
    }

    function getVotingInfo(string calldata votingName) 
        external 
        view
        returns (VotingState votingState, uint votingBalance, bool withDrawOccured, address winnerAddress, address[] memory candidatesAddresses)
    {
        Voting storage voting = votings[votingName];
        return (voting.votingState, voting.votingBalance, voting.withDrawOccured, voting.winnerCandidate.candidateAddress, voting.candidatesAddresses);
    }

    function getVotingCandidateInfo(string calldata votingName, address candidateAddress)
        public
        view
        returns (Candidate memory candidate)  
    {
        Voting storage voting = votings[votingName];
        return voting.candidates[candidateAddress];
    }

    function getVoterInfo(string calldata votingName, address voterAddress)
        public
        view
        returns (Voter memory voter)
    {
        Voting storage voting = votings[votingName];
        return voting.voters[voterAddress];
    }

    function getWinnerCandidate(string calldata votingName) 
        public
        view
        returns (Candidate memory winner)
    {
        Voting storage voting = votings[votingName];
        mapping(address => Candidate) storage candidates = voting.candidates;
        address[] storage candidatesAddresses = voting.candidatesAddresses;
        uint winnerVoteCount = 0;
        Candidate memory candidate;
        for (uint i = 0; i < candidatesAddresses.length; i++) {
            address candidateAddress = candidatesAddresses[i];
            if (candidates[candidateAddress].voteCount > winnerVoteCount) {
                candidate = candidates[candidateAddress];
                winnerVoteCount = candidate.voteCount;
                winner = candidate;
            }
        }
        return winner;
    }
}