// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Vote is Ownable {
    struct UserState {
        bool voted;
    }

    UserState public userstate;

    // map user to if they have voted or not
    mapping(address => UserState) public userToUserState;
    mapping(address => Candidates) public voterToCandidate;
    enum VotingStatus {
        OPEN,
        CLOSED
    }

    VotingStatus public votingstatus;

    uint256 public candidateAvotes;
    uint256 public candidateBvotes;
    uint256 public candidateCvotes;

    enum Candidates {
        candidateA,
        candidateB,
        candidateC
    }

    Candidates public candidatechoice;

    constructor() public {
        userstate.voted = false;
        votingstatus = VotingStatus.CLOSED;
    }

    function startvoting() public onlyOwner {
        require(votingstatus == VotingStatus.CLOSED, "voting is closed");
        votingstatus = VotingStatus.OPEN;
    }

    function voteCandidateA() public {
        require(
            votingstatus == VotingStatus.OPEN,
            "voting has not started yet!"
        );
        require(
            userToUserState[msg.sender].voted == false,
            "you have voted already"
        );
        // what candidate user is voting for
        candidatechoice = Candidates(0);
        voterToCandidate[msg.sender] = candidatechoice;
        // increment that candidates vote count
        candidateAvotes = candidateAvotes + 1;
        userToUserState[msg.sender].voted = true;
    }

    function candidatesAVoteCount() public view returns (uint256) {
        return candidateAvotes;
    }

    function voteCandidateB() public {
        require(
            votingstatus == VotingStatus.OPEN,
            "voting has not started yet!"
        );
        require(
            userToUserState[msg.sender].voted == false,
            "you have voted already"
        );
        // what candidate user is voting for
        candidatechoice = Candidates(1);
        voterToCandidate[msg.sender] = candidatechoice;
        // increment that candidates vote count
        candidateBvotes = candidateBvotes + 1;
        userToUserState[msg.sender].voted = true;
    }

    function candidatesBVoteCount() public view returns (uint256) {
        return candidateBvotes;
    }

    function voteCandidateC() public {
        require(
            votingstatus == VotingStatus.OPEN,
            "voting has not started yet!"
        );
        require(
            userToUserState[msg.sender].voted == false,
            "you have voted already"
        );
        // what candidate user is voting for
        candidatechoice = Candidates(2);
        voterToCandidate[msg.sender] = candidatechoice;
        // increment that candidates vote count
        candidateCvotes = candidateCvotes + 1;
        userToUserState[msg.sender].voted = true;
    }

    function candidatesCVoteCount() public view returns (uint256) {
        return candidateCvotes;
    }

    function totalVoters() public view returns (uint256) {
        uint256 totalvotes = candidateAvotes +
            candidateBvotes +
            candidateCvotes;
        return totalvotes;
    }

    function electionStatus() public view returns (string memory) {
        if (
            candidateAvotes > candidateBvotes &&
            candidateAvotes > candidateBvotes
        ) {
            return "Candidate A is winning!";
        } else if (
            candidateBvotes > candidateAvotes &&
            candidateBvotes < candidateCvotes
        ) {
            return "Candidate C is winning!";
        } else if (
            candidateAvotes == candidateBvotes &&
            candidateAvotes == candidateCvotes
        ) {
            return "No candidate is currently winning, it's a Tie";
        } else {
            return "Candidate B is winning";
        }
    }
}
