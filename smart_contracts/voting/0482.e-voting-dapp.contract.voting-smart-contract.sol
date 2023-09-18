// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

contract VotingContract {

    // Admin Address (Address that deploys the contract)
    address public votingAdmin; 

    // Stores all candidates address
    address[] public candidates;

    // Store all voters address
    address[] public voters;

    // Store address of registered voters that has already voted
    address[] public alreadyVotedVoters;

    // Votes mappings
    mapping(address => uint) public votes;

    // Winner votes number
    uint public winnerVotes;

    address public winner;

    enum votingStatus { NotStarted, Running, Completed }

    votingStatus public status;

    event Vote(address indexed candidate, address indexed voter);
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    constructor() {
        // Set Contract owner (admin)
        votingAdmin = msg.sender;
    }

    // Modifier to make sure only admin calls a function
    modifier OnlyAdmin {
        if(msg.sender == votingAdmin) {
            _;
        }
    }

    // Set voting status
    function setStatus() OnlyAdmin public {
        if (status != votingStatus.Completed) {
            status = votingStatus.Running;
        } else {
            status = votingStatus.Completed;
        }
    }

    // Checks if candidate address has already been registered
    function validateCandidate(address _candidate) view public returns(bool) {
        for (uint i = 0; i < candidates.length; i++) {
             if(candidates[i] == _candidate) {
                 return true;
             }
        }
        return false;
    }

    function alreadyVoted(address _voter) view public returns(bool) {
        for(uint i = 0;  i < alreadyVotedVoters.length; i++){
            if(alreadyVotedVoters[i] == _voter) {
                return true;
            }
        }

        return false;
    }

    function getCandidates() view public returns(address[] memory){
        return candidates;
    }

    function getVoters() view public returns(address[] memory){
        return voters;
    }

    // Checks if voter address has already been registered
    function validateVoter(address _voter) view public returns(bool) {
        for (uint i = 0; i < voters.length; i++) {
             if(voters[i] == _voter) {
                 return true;
             }
        }
        return false;
    }

    // Function to register candidate (accessible to only voting admin)
    function registerCandidate(address _candidate_address) OnlyAdmin public {
        require(!validateCandidate(_candidate_address), "Candidate address already registered.");
        candidates.push(_candidate_address);
    }   
  
    // Give user the right to vote function,
    function registerVoter(address _voter) OnlyAdmin public {
       require(!validateVoter(_voter), "Voter address already registered.");
        voters.push(_voter);
    }  

    // Function to cast a vote
    function vote(address _candidate) public returns(bool) {
        // Check if msg.sender address has been registered as a voter
        require(status == votingStatus.Running, "Election is not active.");
        require(validateVoter(msg.sender) == true, "Voter address not registered.");
        require(validateCandidate(_candidate), "Not a registered candidate.");
        // Check if voter has voted before
        require(alreadyVoted(msg.sender) == false, "Voter has already voted.");

        votes[_candidate] += 1;
        alreadyVotedVoters.push(msg.sender);

        emit Vote(_candidate, msg.sender);
        return true;
    }

    // Returns the votes received for a candidate
    function getVotesCount(address _candidate) public view returns(uint) {
        require(validateCandidate(_candidate), "Not a registered candidate");
        require(status == votingStatus.Running, "Election is not active.");
        return votes[_candidate];
    }

    // Returns winner of vote
    function result() public {
        require(status == votingStatus.Completed, "Election is still in progress.");
        for(uint i = 0; i < candidates.length; i++) {
            if (votes[candidates[i]] > winnerVotes) {
                winnerVotes = votes[candidates[i]];
                winner = candidates[i];
            }
        }
    }
}
