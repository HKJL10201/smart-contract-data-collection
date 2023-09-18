pragma solidity ^0.4.13;

contract VotingStore {

  uint public votingIndex;
  
  // struct Option {
  //   uint id;
  //   string name;
  //   string descLink;
  //   string imageLink;
  //   string descLink;
  // }

  struct Voting {
    uint id;
    string name;
    string descLink;
    string category;
    uint startTime;
    uint endTime;
    // mapping (uint => Option) optionList;
    bytes32[] optionList;
    address owner;
    mapping (address => Voter) votes;
    mapping (bytes32 => uint) summaryVotes;
  }

  // We use the struct datatype to store the voter information.
  struct Voter {
    address voterAddress; // The address of the voter
    bytes32 option; // Option which choosed from the voter
  }

 mapping (address => mapping(uint => Voting)) votingList; //list of voting
 mapping (uint => address) votingIndexes; 

 function VotingStore() public {
  votingIndex = 0;
 }

 function registerVoting(string _name, string _descLink, string _category, uint _startTime, uint _endTime, bytes32[] _optionList) public {
  require (_startTime < _endTime);
  votingIndex += 1;
  Voting memory voting = Voting(votingIndex, _name, _descLink, _category, _startTime, _endTime, _optionList, msg.sender);

  votingList[msg.sender][votingIndex] = voting;
  votingIndexes[votingIndex] = msg.sender;
 }

 function getVoting(uint _votingIndex) view public returns (uint, string, string, string, uint, uint, bytes32[]) {
   Voting memory voting = votingList[votingIndexes[_votingIndex]][_votingIndex];
   return (voting.id, voting.name, voting.descLink, voting.category, voting.startTime, voting.endTime, voting.optionList);
 }

 function voteToOption(uint _votingIndex, bytes32 _option) public returns (bool) {
   Voting storage voting = votingList[votingIndexes[_votingIndex]][_votingIndex];
   require (voting.votes[msg.sender].voterAddress == 0);
   votingList[votingIndexes[_votingIndex]][_votingIndex].votes[msg.sender] = Voter(msg.sender, _option);
   require (now <= voting.endTime);
   uint index = findIndexOfOption(_votingIndex, _option);
   require(index != uint(-1));
   votingList[votingIndexes[_votingIndex]][_votingIndex].votes[msg.sender] = Voter(msg.sender, _option);
   votingList[votingIndexes[_votingIndex]][_votingIndex].summaryVotes[_option] += 1;
   return true;
 }

 function findIndexOfOption(uint _votingIndex, bytes32 option) public returns (uint) {
   Voting memory voting = votingList[votingIndexes[_votingIndex]][_votingIndex];
    for( uint index = 0; index < voting.optionList.length; index++ ) {
      if (voting.optionList[index] == option) {
        return index;
      }
    }
    return uint(-1);
 }

}