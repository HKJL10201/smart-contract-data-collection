// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Election {
  struct Candidate {
    uint uuid;
    string name;
    string party;
    uint voteCount;
  }

  struct Voter {
    address uid;
    bool voted;
  }

  address private admin;
  enum status {INIT, LIVE, OVER} status private electionStatus;
  bool private start;
  bool private end;
  
  string electionTitle;
  string electionOrganization;
  uint private candidateCount;

  constructor() {
    admin = msg.sender;
    candidateCount = 0;
    electionStatus = status.INIT;
    start = false;
    end = false;
  }
  

  Candidate[] private candidateList;
  mapping(uint => Candidate) private candidateMap;
  mapping(address => Voter) public voterList;


  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  /**
    * admin Funcs
  */

  function addCandidate(string memory _name, string memory _party) public onlyAdmin {
    require(electionStatus == status.INIT);

    Candidate memory c = Candidate({ name: _name, party: _party, uuid: candidateCount, voteCount: 0 });
    
    candidateMap[candidateCount] = c;
    candidateList.push(c);
    
    candidateCount++;
  }


  function addVoters(address[] memory voters) public onlyAdmin {
    require(electionStatus == status.INIT);

    for(uint i = 0; i < voters.length; i++) {
      Voter memory v = Voter({ uid: voters[i], voted: false });
      voterList[voters[i]] = v;
    }
  }


  function startElection() public onlyAdmin {
    require(start == false);

    electionStatus = status.LIVE;
    start = true;
  }


  function endElection() public onlyAdmin {
    require(start == true);
    require(end == false);

    electionStatus = status.OVER;
    end = true;
  }


  function setElectionDetails(string memory title, string memory org) public onlyAdmin {
    require(electionStatus == status.INIT);
    electionTitle = title;
    electionOrganization = org;
  }

  /**
    * Public Funcs
  */

  function getCandidates() public view returns(Candidate[] memory) {
    return candidateList;
  }


  function getElectionStatus() public view returns(status) {
    return electionStatus;
  }


  function getElectionDetails() public view returns(string memory, string memory, status) {
    return (electionTitle, electionOrganization, electionStatus);
  }


  function vote(uint id) public {
    require(electionStatus == status.LIVE);

    require(voterList[msg.sender].uid != address(0));
    require(voterList[msg.sender].voted == false);

    candidateList[id].voteCount++;
    voterList[msg.sender].voted = true;
  }
}
