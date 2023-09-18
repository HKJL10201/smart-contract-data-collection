// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @title Voting contract for INEC
/// @author Glory Praise Emmanuel
/// @notice A contract that allows you add candidates, vote and view candidates details, voters details and vote results

contract Vote {

  address INEC;

  uint public candidateCount;

  uint public votersCount;

  string votePassCode;

  uint electionTime = block.timestamp + 30 minutes;

  struct Candidate {
    string candidateName;
    string candidateParty;
    uint ballotNumber;
    uint voteCount;
  }

  struct Voter {
    bool voted;
  }

  mapping (address => Voter) voters;

  mapping (uint => Candidate)  candidateNumber;

  modifier onlyOwner {
    require(msg.sender == INEC, "Only INEC can call this function");
    _;
  }

  modifier electionTimeChecker {
    require(block.timestamp < electionTime, "Election time has elaspsed, try again next election");
    _;
  }

  modifier startElection {
    require(candidateCount >= 3, "Election can't start yet! Add more candidates");
    _;
  }

  constructor() {
    INEC = msg.sender;
    candidateCount = 0;
    votePassCode = "ILOVENIGERIA";
  }

  /// @dev Returns a single candidate name, ballot number, party and total votes
  function viewCandidate(uint id) external view returns ( uint ballotNumber, string memory candidateName, string memory candidateParty, uint voteCount) {
      candidateName = candidateNumber[id].candidateName;
      ballotNumber = candidateNumber[id].ballotNumber;
      candidateParty = candidateNumber[id].candidateParty;
      voteCount = candidateNumber[id].voteCount;
  }

  /// @dev Returns all candidate names and total votes
   function viewResults() external view returns (string[] memory, uint[] memory) {
        string[] memory candidateName = new string[](candidateCount);
        uint[] memory candidateVoteCounts = new uint[](candidateCount);
        for (uint i = 0; i < candidateCount; i++) {
            candidateName[i] = candidateNumber[i].candidateName;
            candidateVoteCounts[i] = candidateNumber[i].voteCount;
        }
        return (candidateName, candidateVoteCounts);
  }

  /// @dev returns if a voter has already voted
  function viewVoterDetails(address address_) public view returns (bool voted){
      voted = voters[address_].voted;
  }

  /// @dev add new candidate
  function addCandidate(uint id, string memory candidateName_, string memory candidateParty_) external onlyOwner returns (uint) {
    Candidate storage candidate = candidateNumber[id];
    candidate.ballotNumber = id ;
    candidate.candidateName = candidateName_;
    candidate.candidateParty = candidateParty_;
    candidate.voteCount = 0;
    candidateCount++;
    return id;
  }

  /// @dev vote function 
  function vote(uint ballotNumber_, string memory votePassCode_ ) external startElection electionTimeChecker {
    require(voters[msg.sender].voted == false, "You have already voted, come back next election");
    require(keccak256(abi.encodePacked(votePassCode)) == keccak256(abi.encodePacked(votePassCode_)), "Wrong passcode, You can't vote, input correct passcode");
    candidateNumber[ballotNumber_].voteCount++;
    voters[msg.sender].voted = true;
    votersCount++;
  }
}