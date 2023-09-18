//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract VotingSystem{
 struct Nominee{
     string name;
     uint256 noOfVotes;
 }
 

 struct Voter{
     address voterAddress;
     bool isRegistered;
     bool isVoted;
     bool pass;
 }

 address public chairman;
 uint256 public expiryTime;
 uint256 public winnerIndex;
 uint256 public winnerVoteCount;
 Nominee[] public nomineeList;
 Voter[] public proposedVoters;
 address[] public _rejectedVoters;

 mapping(address=>Voter) public voterList;
 event registrationStatus(address _voterAddress);
 event votingStatus(address _voterAddress, bool _isVoted);

 //Errors
 error invalidAmount(string);
 error cannotDoneTwice(string);
 error chairmanCannotVote();
 error voteIsEnded();
 error notEndedYet();
 error notEligible(string);
 //Modifiers
 modifier onlyChairman(){
     if(msg.sender != chairman){
        revert notEligible("Only chairman can call");
     }
     _;
 }
 modifier registrationRules(){
     if(voterList[msg.sender].isRegistered == true){
         revert cannotDoneTwice("You can't register twice");
     }
     if(voterList[msg.sender].pass == true){
        revert cannotDoneTwice("You can't add twice");
     }
     if(msg.sender == chairman){
        revert chairmanCannotVote();
     }
     if(block.timestamp > expiryTime){
        revert voteIsEnded();
     }
     _;
 }
 
 modifier votingRules(){
     if(msg.sender == chairman){
        revert chairmanCannotVote();
     }
     if(voterList[msg.sender].pass == false){
        revert notEligible("You don't have pass");
     }
     if(voterList[msg.sender].isVoted == true){
        revert cannotDoneTwice("You can't vote twice");
     }
     if(block.timestamp>expiryTime){
        revert voteIsEnded();
     }
     _;
 }
 constructor(string[] memory _nominees){
   for(uint i=0;i<_nominees.length;i++){
    nomineeList.push(Nominee({
        name : _nominees[i],
        noOfVotes : 0

    }));
   }}

//Functions
function getChairman() external view returns(address){
   return chairman;
}

function setExpiryTime(uint256 _expiryTime) external{
expiryTime = _expiryTime;
chairman = msg.sender;
}

function getExpiryTime() external view returns(uint256){
   return expiryTime;
}

function getNomineeListLen() external view returns(uint256){
   return nomineeList.length;
}
function getVoterListLen() external view returns(uint256){
   return proposedVoters.length;
}
 function register() external registrationRules {
   proposedVoters.push(Voter({voterAddress:msg.sender,isRegistered:true,isVoted:false,pass:false}));
 }
 function rejectVoter(uint _voterIndex) public onlyChairman{
  _rejectedVoters.push(proposedVoters[_voterIndex].voterAddress);
  for(uint i=_voterIndex; i<proposedVoters.length-1; i++){
      proposedVoters[i] = proposedVoters[i+1];
  }
  proposedVoters.pop();
 }

 function approveVoters() public onlyChairman{
    for(uint i=0; i<proposedVoters.length;i++){
    Voter storage _voter = voterList[proposedVoters[i].voterAddress];
    _voter.voterAddress = proposedVoters[i].voterAddress;
    _voter.isRegistered = true;
    _voter.pass = true;
    emit registrationStatus(proposedVoters[i].voterAddress);
    }
    }

 function vote(uint256 _index) external votingRules {
    Voter storage _voter = voterList[msg.sender];
    _voter.isVoted = true;
    nomineeList[_index].noOfVotes+=1;
    emit votingStatus(msg.sender, true);
 }

 function findWinner() external  {
    if(msg.sender != chairman){
        revert notEligible("Only Chairman can call this function");
    }
    if(block.timestamp<expiryTime){
        revert notEndedYet();
    }
    for(uint j=0; j<nomineeList.length; j++){
        if(nomineeList[j].noOfVotes > winnerVoteCount){
            winnerVoteCount = nomineeList[j].noOfVotes;
            winnerIndex = j;
        }
        else{winnerVoteCount = winnerVoteCount ;}
    }

   
 }
    function getWinner() external view returns(uint256){
      return winnerIndex;
    }

}
