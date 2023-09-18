pragma solidity ^0.8.0;
//make a voting contract

//1. we want the ability to accept proposals and store them
//candidate: their name and number(to keep track of the candidate)

//2. voters and voting ability
//keep track of voting 
//check voters are authenticated to vote

//3. chairperson
// authenticate and deploy contract


contract Ballot{
  
  //voters: voted, access to vote, vote index

  struct Voter{
  bool voted;
  uint vote;
  uint weight;
  }

  struct Proposal{
      string name; //name of each proposal
      uint voteCount; //no of accumulated vote
  }
  Proposal[] public candidate;

  //mapping allows for us to create a store value with keys and indexes\
  mapping(address => Voter) public voters; //voters get address as a key and voter for value

  address public chairperson;

  constructor( string[] memory proposalNames) {

chairperson = msg.sender;

//add 1 to chairperson's weight

voters[chairperson].weight = 1;

      for(uint i=0; i < proposalNames.length; i++){
  
  candidate.push(Proposal(proposalNames[i],0));        
      }
  }

    //function to authenticate vote
function giveRightToVote(address voter) public {
 require(msg.sender == chairperson, 'you are not the chairperson and only her can give access');   
//rerquire that voter has not vote
require(!voters[voter].voted, 'the voter has voted'); //the voter with this addresss in our mapping has not vote yet
require(voters[voter].weight == 0, 'the voter has voted');
voters[voter].weight = 1;

}

  //function for voting
function vote(uint proposal) public{
    Voter storage sender = voters[msg.sender];
    require(sender.weight !=0, 'Has no right to vote');
    require(!sender.voted, 'Already voted');
sender.voted = true;
sender.vote = proposal;

candidate[proposal].voteCount = candidate[proposal].voteCount + sender.weight;
}


//functions for showing the results
//function that shows the winning proposal by integer
//function that shows the winning proposal by name

function winningcandidate() public view returns(uint winningProposal_){
uint winningVoteCount = 0;
  for(uint i = 0; i < candidate.length; i++ ){

    if(candidate[i].voteCount > winningVoteCount){
	winningVoteCount = candidate[i].voteCount;
	winningProposal_ = i;
      }

  }
}

function winningName() public view returns(string memory winningName_){
winningName_ = candidate[winningcandidate()].name;

}

}
