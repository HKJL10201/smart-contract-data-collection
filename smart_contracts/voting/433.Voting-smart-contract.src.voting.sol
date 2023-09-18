// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;
contract Voting{
/////////////////*****STATE VARIABLES ******////////////////////////
uint id = 1;



/////////////////*****STRUCTS ******////////////////////////


struct VotingPoll{
    uint id;
    string name;
    address chairman;
    address[] candidates;
    uint32 maxNoOfCandidates;
    uint32 currentNoOfCandidates;
    bool voting;
}




/////////////////*****ARRAY ******////////////////////////

uint[] public VotingKey;
VotingPoll[] public retVotingPoll;

uint[] public _ids;

/////////////////*****MAPPINGS *////////////////////////
mapping(uint => VotingPoll) public votingPoll;
mapping (address => uint256) public replayNonce;
mapping (uint => mapping(address=>bool))  CandidateStatus; 
mapping(uint => mapping (address => uint))  CandidateVote;    
mapping (uint => mapping(address=>bool)) hasVoted;

/////////////////*****EVENTS ******////////////////////////

event voted(address _candidate, bool status);
event becameCandidate(address NewCandidate);
event pollCreated(string indexed _name, uint32 indexed ExpectedNoOfCandidate, uint indexed _id);
event voteStatus(bool indexed status);

/////////////////*****MODIFIERS *****////////////////////////

modifier isCandidate(address Cand, uint _id){
    require(CandidateStatus[_id][Cand]==true,'This address does not exist as a candidate');
    _;
}
modifier StillVoting(uint _id){
    VotingPoll storage VP = votingPoll[_id];
    require(VP.voting == true, "voting has ended");
        _;
}

/////////////////*****CONSTRUCTORS ******////////////////////////


/////////////////*****FUNCTIONS ******////////////////////////

function createPoll(string memory _name, uint32 ExpectedNoOfCandidate) external {
    VotingPoll storage VP = votingPoll[id];
    VP.name = _name;
    VP.chairman = msg.sender;
    VP.id =id;
    VP.maxNoOfCandidates =ExpectedNoOfCandidate;
    retVotingPoll.push(VP);
    emit pollCreated( _name, VP.maxNoOfCandidates, id);
    _ids.push(id);
    id++;

}

 function AddCandidate(address _newCandidate, uint _id) external{
     VotingPoll storage VP = votingPoll[_id];
     require (VP.chairman != address(0) , "yet to create a poll");  
     assert(VP.chairman == msg.sender);
     require(VP.currentNoOfCandidates < VP.maxNoOfCandidates, "maximum no of candidate per session registered");
     CandidateStatus[_id][_newCandidate] = true; 
     VP.candidates.push(_newCandidate); 
     VP.currentNoOfCandidates++;
     emit becameCandidate(_newCandidate);
 }

 function vote(address Cand, uint _id, uint256 nonce, bytes memory signature) external  isCandidate(Cand, _id) StillVoting(_id){
     bytes32 metaHash = metaVotingHash(Cand,_id,nonce,block.timestamp);
     address signer = getSigner(metaHash,signature);
     require(signer!=address(0));
    require(nonce == replayNonce[signer]);
    replayNonce[signer]++;
     require(hasVoted[_id][signer] == false, "You already voted");
     countVote(Cand, _id, signer);
     emit voted(Cand, true);

 }

  function countVote(address Cand, uint _id, address signer) internal returns(uint){
     hasVoted[_id][signer] = true;
     CandidateVote[_id][Cand]++;
     return CandidateVote[_id][Cand];
  }

  function setVotingState( uint _id) external {
    VotingPoll storage VP = votingPoll[_id];
    require(VP.chairman == msg.sender, "not the chairman");     
     VP.voting = !(VP.voting);
     emit voteStatus(VP.voting);
 }

 function NoOfRegisteredCandidates( uint _id) public view returns(uint){
     VotingPoll storage VP = votingPoll[_id];
     return VP.currentNoOfCandidates;
 }  

 function AllCandidates( uint _id) public view returns(address[] memory _candidates){
     VotingPoll storage VP = votingPoll[_id];
     return VP.candidates;
 }

 function revealWinner( uint _id) external view returns ( uint[] memory CV, address, uint){
     VotingPoll storage VP = votingPoll[_id];
     require(VP.chairman != address(0), "No poll created");
     CV = new uint[](VP.candidates.length);
     uint highestVote;
     address winner;
     for (uint i = 0; i < VP.candidates.length; i++){
       uint val = getPosition(_id,i);
     if(val > highestVote){
         highestVote = val; 
         winner = VP.candidates[i];
     }
     CV[i] = (CandidateVote[_id][VP.candidates[i]]);

     }
     return (CV, winner, highestVote);
 }

 

 function getPosition( uint _id, uint i) private view returns(uint val){
     VotingPoll storage VP = votingPoll[_id];
       val = CandidateVote[_id][VP.candidates[i]];
 }

 

 function getVotePollProps(uint _id) public view returns(VotingPoll memory){
   return votingPoll[_id];
 }

 function getAllVotingPolls() external view returns(VotingPoll[] memory VP){
  VP = new VotingPoll[](id);
  for(uint i = 0; i< id; i++){
    VP[i] = getVotePollProps(i++);
  }
 }

 
 function metaVotingHash(address Cand, uint _id, uint256 nonce, uint256 time) public view returns(bytes32){
    return keccak256(abi.encodePacked(address(this),"metatransaction Voting ", Cand, _id, nonce, time));
  }

  function getSigner(bytes32 _hash, bytes memory _signature) internal pure returns (address){
    bytes32 r;
    bytes32 s;
    uint8 v;
    if (_signature.length != 65) {
      return address(0);
    }
    assembly {
      r := mload(add(_signature, 32))
      s := mload(add(_signature, 64))
      v := byte(0, mload(add(_signature, 96)))
    }
    if (v < 27) {
      v += 27;
    }
    if (v != 27 && v != 28) {
      return address(0);
    } else {
      return ecrecover(keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
      ), v, r, s);
    }
  }

function allIds() public view returns(uint[] memory){
return _ids;
}

}