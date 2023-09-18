pragma solidity ^0.8.17;
contract modifiedVotingSystem {

uint candidateCount;
address public owner;
bool start;
bool end;

// Constructor
function VotingSystem() public {
   owner=msg.sender;
   candidateCount = 0;
   start=false;
   end=false;
}

function getOwner() public view returns(address) {
   return owner;
}

// Only Admin can access
modifier onlyAdmin() {
   require(msg.sender == owner);
   _;
}

struct Candidate{
   string name;
   string party;
   uint voteCount;
   uint candidateId;
}
mapping(uint => Candidate) public candidateDetails;

function addCandidate(string memory _name, string memory _party) public  {
   Candidate memory newCandidate = Candidate({
     name : _name,
     party : _party,
     voteCount : 0,
     candidateId : candidateCount
   });
   candidateDetails[candidateCount] = newCandidate;
   candidateCount += 1;
}

function getCandidate(uint candidateNo) public view returns (uint) {
   return candidateDetails[candidateNo].voteCount;
}



struct Voter{
   string voterId;
   address ethAddress;
   string candidateVotedTo;
   bool hasVoted;
   bool isVerified;
}
address[] public voters;
string[] public voteCount;
string[] public alreadyVoted;
mapping(address => Voter) public voterDetails;
// request to be added as voter
function requestVoter(string  memory _id, address _ethAddress,string memory _candidate) public {
   Voter memory newVoter = Voter({
     voterId : _id,
     ethAddress : _ethAddress,
     candidateVotedTo: _candidate,
     hasVoted : false,
     isVerified : false
   });
   voterDetails[_ethAddress] = newVoter;
   voters.push(_ethAddress);
   voteCount.push(_candidate);
   alreadyVoted.push(_id);
}

function getVoteCount() public view returns(string[] memory){
   return voteCount;
}

function getVoterId() public view returns(string[] memory){
   return alreadyVoted;
}

function verifyVoter(address _address) public {
   voterDetails[_address].isVerified = true;
}
function vote(uint candidateId, address ethAddress) public {
   require(voterDetails[ethAddress].hasVoted == false);
   candidateDetails[candidateId].voteCount+=1;
   voterDetails[ethAddress].hasVoted = true;
}

function startElection() public {
   start = true;
   end = false;
}
function endElection() public {
   end = true;
   start = false;
}
function getStart() public view returns (bool) {
   return start;
}
function getEnd() public view returns (bool) {
   return end;
}
}