// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// Import this file to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingDapp {

    mapping(address => bool) public registeredVoters;
    mapping(address => bool) public registeredCandidates;
    mapping(address => bool) public castedVotes;

    address[] candidatesArr;
    int[] votesPerCandidate;
    address winner;

    bool public electionInProgress;
    bool public registrationInProgress;
    bool public votingInProgress;

    uint256 registrationDeadline;
    uint256 votingDeadline;

    bool public concluded;

    modifier registeredVoter() {
        require(registeredVoters[msg.sender] == true, "You are NOT a registered voter. Plz register");
        _;
    }

    function registerAsVoter() public {
        require( registeredVoters[msg.sender] == false, "You are already registered as a Voter");
        registeredVoters[msg.sender] = true;
    }

    function registerAsCandidate() public registeredVoter {

        require( registeredCandidates[msg.sender] == false, "You are already registered as a Candidate");
        require(registrationInProgress, "Registration period is NOT active");
        
        registeredCandidates[msg.sender] = true;
        candidatesArr.push(msg.sender);
    }

    function startRegistration() public registeredVoter {

        require(!registrationInProgress, "Registration already in progress");

        registrationDeadline = block.timestamp + 5 minutes;

        electionInProgress = true;
        registrationInProgress = true;
    }

    function startElection() public registeredVoter {

        require(!votingInProgress, "Voting already in progress");
        require(registrationInProgress, "Election cannot start without Registration");

        votingDeadline = block.timestamp + 5 minutes;

        votesPerCandidate = new int[](candidatesArr.length);

        registrationInProgress = false;
        votingInProgress = true;
    }

    function endElection() public registeredVoter {

        require(electionInProgress, "Election is NOT in progress");
        require(block.timestamp > votingDeadline, "Voting deadline NOT over yet");

        uint maxVotesIndex;
        int maxVotes = 0;

        for (uint i = 0; i < votesPerCandidate.length; i++) {
            
            if (votesPerCandidate[i] > maxVotes) {
                maxVotesIndex = i;
            }
        }

        winner = candidatesArr[maxVotesIndex];

        votingInProgress = false;
        electionInProgress = false;
        concluded = true;
    }

    function getCandidates() public view returns (address[] memory) {

        return candidatesArr;
    }

    function vote(uint forVoteIndex) public registeredVoter {

        console.log("Candidate address at index %s is %s", forVoteIndex, candidatesArr[forVoteIndex]);
        // console.log("", registeredCandidates[candidatesArr[forVoteIndex]]);

        require(registeredCandidates[candidatesArr[forVoteIndex]], "The voted candidate is NOT a registered candidate");
        int i = votesPerCandidate[forVoteIndex];
        votesPerCandidate[forVoteIndex] = i++;

        castedVotes[msg.sender] = true;
    }

    function getWinner() public view returns (address) {

        return winner;
    }


}