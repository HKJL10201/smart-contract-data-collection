// SPDX-License-Identifier: MIT
pragma solidity  <= 0.8.12;

contract Election {
  //Structure of candidate standing in the election
  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }
  //Storing candidates in a map
  mapping(uint => Candidate) public candidates;
  //Number of candidates in standing in the election
  uint public candidatesCount;
  //Storing address of those voters who already voted
  mapping (address => bool) public voters;
   //Adding 2 candidates during the deployment of contract
  constructor () {
    addCandidate("Candidate 1");
    addCandidate("Candidate 1");
  }
  