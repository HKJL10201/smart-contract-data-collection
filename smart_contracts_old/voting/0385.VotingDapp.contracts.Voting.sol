// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting  is Ownable  {

  //EVENTS DEC 
    event Vote(address indexed _from,  uint _value);

  // Structs acts as Model  
  struct Candidate {
    uint id;
    string name;
  }
  struct votesReceived{
    uint candidateId ;
    uint256 counter; 
  }


  /* mapping field is similar to hash tables in python or dict.*/
  mapping(uint => Candidate) public candidates;
  mapping(uint => votesReceived) public votes;
  mapping(address => bool) public voters;


  bool _isActive = true;
  // I just decide to no pass arguments to the constructor as array is not supported. 
  // Also place the data inside the constructor method is a guarantee
  // I can Use IFPS to store candidate list and handle using update  method 
  constructor()   {

    addCandidate(1, 'John Doe');
    addCandidate(2, 'Jane Doe');
    addCandidate(3, 'Gary Jeff');

  }

  modifier _checkActive() {
    require (_isActive);
    _;
  }
  

  function addCandidate(uint32 _number, string memory _name) private {
    candidates[_number] = Candidate(_number, _name);
  }

  function vote(uint _candidate)  _checkActive public {
    require(validCandidate(_candidate),"Invalid Candidate");
    require(!voters[msg.sender], "You can't vote multiple times");
    voters[msg.sender] = true;
    votes[_candidate].counter ++;
    emit Vote(msg.sender, _candidate);
  }

  // Views functions not use gas 
  // Return total Votes
  function countVotes(uint _candidate) view public returns (uint) {
    require(validCandidate(_candidate),"Invalid Candidate");
    return votes[_candidate].counter;
  }

  // work around to check if the candidate is in the list
  function validCandidate(uint _candidate) view public returns (bool) {
    if(candidates[_candidate].id != 0){
      return true;
    }else{
      return false;
    }
  }

  function setActivity(bool isActive) onlyOwner public {
    // restrict access to this function
    _isActive = isActive;
  }

}