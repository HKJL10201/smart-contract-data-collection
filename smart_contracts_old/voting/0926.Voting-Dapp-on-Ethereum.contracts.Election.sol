// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

contract Election {
  //model candidate using struct
  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }
  //store Id has voted
  mapping(address => bool ) public voters;
  // Store candidates in mapping
  //Fetch Candidate
  mapping(uint => Candidate) public candidates;
  //store candidates count as we want to track no
  uint public candidatesCount;
// constructor defination in old version of solidity. In newer version you donot need to add function keyword and functionName
//Constructor gets called automatically once contract is migrated on blockchain.
//smart contract is in control of candidates addition. externally we cannot add candidate
  //voted event to get candidates already voted

  
  constructor() public {
    addCandidate("Candidate 1");
    addCandidate("Candidate 2");
  }
  function addCandidate (string memory _name) private {
    //function is private so that noone will be able to add new candidate after deployment
    //candidesCount is increased first and is passed as uint which is id
    candidatesCount ++;
    //candidate is array and we are passing  candidateCount as array no.
    candidates[candidatesCount] = Candidate(candidatesCount, _name,0);
  }
 function vote (uint _candidateId) public {
    // require that they haven't voted before
    require(!voters[msg.sender]);

    // require a valid candidate
    require(_candidateId > 0 && _candidateId <= candidatesCount);

    // record that voter has voted
    voters[msg.sender] = true;

    // update candidate vote Count
    candidates[_candidateId].voteCount ++;

    // trigger voted event
    votedEvent(_candidateId);
}
}