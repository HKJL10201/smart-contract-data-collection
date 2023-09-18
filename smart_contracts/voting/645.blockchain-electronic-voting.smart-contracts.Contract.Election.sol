// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ElectionFact {
  struct ElectionDet {
    address deployedAddress;
    string el_n;
    string el_d;
  }

  mapping(string => ElectionDet) companyEmail;

  function createElection(
    string memory email,
    string memory election_name,
    string memory election_description
  ) public {
    Election newElection = new Election(
      msg.sender,
      election_name,
      election_description
    );

    companyEmail[email].deployedAddress = address(newElection);
    companyEmail[email].el_n = election_name;
    companyEmail[email].el_d = election_description;
  }

  function getDeployedElection(string memory email)
    public
    view
    returns (
      address,
      string memory,
      string memory
    )
  {
    address val = companyEmail[email].deployedAddress;
    if (val == address(0)) {
      return (address(0), '', 'Create an election.');
    } else {
      return (
        companyEmail[email].deployedAddress,
        companyEmail[email].el_n,
        companyEmail[email].el_d
      );
    }
  }
}

contract Election {
  address election_authority;
  string election_name;
  string election_description;
  bool status;

  constructor(
    address authority,
    string memory name,
    string memory description
  ) {
    election_authority = authority;
    election_name = name;
    election_description = description;
    status = true;
  }

  modifier owner() {
    require(msg.sender == election_authority, 'Error: Access Denied.');
    _;
  }

  struct Candidate {
    string candidate_name;
    string candidate_description;
    string imgHash;
    uint8 voteCount;
    string email;
  }

  mapping(uint8 => Candidate) public candidates;

  struct Voter {
    uint8 candidate_id_voted;
    bool voted;
  }

  mapping(string => Voter) voters;
  uint8 numCandidates;
  uint8 numVoters;

  function addCandidate(
    string memory candidate_name,
    string memory candidate_description,
    string memory imgHash,
    string memory email
  ) public owner {
    uint8 candidateID = numCandidates++; //assign id of the candidate
    candidates[candidateID] = Candidate(
      candidate_name,
      candidate_description,
      imgHash,
      0,
      email
    );
  }

  function vote(uint8 candidateID, string memory e) public {
    require(!voters[e].voted, 'Error:You cannot double vote');

    voters[e] = Voter(candidateID, true);
    numVoters++;
    candidates[candidateID].voteCount++; //increment vote counter of candidate
  }

  function getNumOfCandidates() public view returns (uint8) {
    return numCandidates;
  }

  function getNumOfVoters() public view returns (uint8) {
    return numVoters;
  }

  function getCandidate(uint8 candidateID)
    public
    view
    returns (
      string memory,
      string memory,
      string memory,
      uint8,
      string memory
    )
  {
    return (
      candidates[candidateID].candidate_name,
      candidates[candidateID].candidate_description,
      candidates[candidateID].imgHash,
      candidates[candidateID].voteCount,
      candidates[candidateID].email
    );
  }

  function winnerCandidate() public view owner returns (uint8) {
    uint8 largestVotes = candidates[0].voteCount;
    uint8 candidateID;
    for (uint8 i = 1; i < numCandidates; i++) {
      if (largestVotes < candidates[i].voteCount) {
        largestVotes = candidates[i].voteCount;
        candidateID = i;
      }
    }
    return (candidateID);
  }

  function getElectionDetails()
    public
    view
    returns (string memory, string memory)
  {
    return (election_name, election_description);
  }
}
