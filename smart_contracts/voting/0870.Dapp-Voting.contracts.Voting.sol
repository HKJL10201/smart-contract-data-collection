pragma solidity ^0.4.17;

/*Simple contract which allows users to vote in a binary vote*/
contract Voting {

// Structures used in the contract
struct Ballot{
    address voter;
    uint ballotID;
    uint result;
  }

struct Vote{
  uint voteId;
  address owner;
  string voteName;
  string voteDescription;
  uint currentVotesFor;
  uint currentVotesAgainst;
  uint numberOfVoters;
  bool voteOngoing;
  //Map voters to thier votes
  mapping(address => Ballot) ballots;
}

//state variables

//Keep track of all Votes
mapping(uint => Vote) public votes;

//counter to use as unique id
uint public voteCounter;

//modifiers


// add a vote
function createVote(string _voteName, string _voteDescription) public {
  voteCounter++;
  votes[voteCounter] = Vote(
    voteCounter,
    msg.sender,
    _voteName,
    _voteDescription,
    0,
    0,
    0,
    true
    );

}

function getVoteDetails() public view returns(bool){
  return false;
}

function getVoteBallot(uint _voteId) public view returns(address, uint, uint){
  // ensure vote exists
  require(votes[_voteId].owner != 0x0);
  address retVoter = votes[_voteId].ballots[msg.sender].voter;
  uint retBallotid = votes[_voteId].ballots[msg.sender].ballotID;
  uint retResult = votes[_voteId].ballots[msg.sender].result;
  return (retVoter, retBallotid, retResult);
}

//Let a voter cast thier vote. 1 is a vote for and 0 is a vote against
function castVote(uint _voteId, uint _option) public {
  //ensure a valid value is passed in the argument
  require(_option == 1 || _option == 0);
  // ensure vote exists by checking that the owner is set
  require(votes[_voteId].owner != 0x0);
  //ensure the vote is open
  require(votes[_voteId].voteOngoing);
  // ensure the voter has not already cast a vote
  require(votes[_voteId].ballots[msg.sender].voter == 0x0);

  /*register the vote in the voting mapping*/
  //increment the number of numberOfVoters
  votes[_voteId].numberOfVoters++;
  //register the vote
  votes[_voteId].ballots[msg.sender] = Ballot(
    msg.sender,
    votes[_voteId].numberOfVoters,
    _option
    );

  // track the results TODO
}

// allow the owner to close the voting
function closeVote(uint _voteId) public {
  // ensure vote exists by checking that the owner is set
  require(votes[_voteId].owner != 0x0);
  //ensure the vote not already closed
  require(votes[_voteId].voteOngoing);
  //ensure the sender is the owner of the vote
  require(votes[_voteId].owner == msg.sender);

  //close the vote
  votes[_voteId].voteOngoing = false;
}

// TODO
function getResults()  public view  returns (bool){
    return (false);
}


}
