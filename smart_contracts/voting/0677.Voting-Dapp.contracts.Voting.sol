// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.8.12;


contract Voting {

//token name
 string public name = "Dapp Voting";


// voting party options
uint public democrat;

uint public republican;

// each vote
 struct Vote {
     uint256 id;
     address  Address;
     string   text;
     bool    voted;
     uint256   timestamp;
 }
  
  Vote voter;

// events when votes are casted
event VoteCasted(string indexed _choice);


//total number of votes
 uint public numberOfVotes;

//eligible voter
 mapping (address => Vote) person;

// prevent duplicate votes
 modifier duplicateVotes (address Address) {
  require(person[Address].voted == false , "already voted before");
  _;
 }


// Cast a vote
// Validate voter to ensure that voter has not voted before
// Assign votes to voted candidates to be able to pick a winner from the client
// calculate the total number of votes

function castVote(string memory _text, uint256 id) public duplicateVotes(msg.sender) {

    Vote memory _newVote = Vote(id, msg.sender, _text, true, block.timestamp);
    
    voter = _newVote;

    person[msg.sender] = voter;

    keccak256(abi.encodePacked(_text)) == keccak256(abi.encodePacked("republican"))
     ? republican++ : democrat++;

    numberOfVotes++;

    emit VoteCasted(_text);

    
    
    
}



}