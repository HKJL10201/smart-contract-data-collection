pragma solidity ^0.5.0;
contract Election {
    uint electionCount=0;
    struct CandidateInfo {
        string id;
        uint vote;
    }
    struct UserVoteInfo{
      string id;
      string candidateId;
    }
    struct ElectionUserInfo{
      string electionName;
      uint cnt;
      mapping(string => UserVoteInfo) users;
    }
    mapping(string => CandidateInfo) candidatesVote;
    mapping(string => ElectionUserInfo) electionUsers;

    struct UserVoteInfo1{
      uint votesCnt;
      string[] isvote;
    }
    mapping(string => string[]) userVotes ;
    function setVote(string memory _candidateId,string memory _username,string memory _electionName) public returns(string memory){
    candidatesVote[_candidateId].vote++;
    
   if(electionUsers[_electionName].cnt==0){
      electionUsers[_electionName].electionName=_electionName;
      electionUsers[_electionName].users[_username]=UserVoteInfo(_username,_candidateId);
      electionUsers[_electionName].cnt=1;
      // electionUsers[_electionName]=electionUser;
    }else{
      electionUsers[_electionName].users[_username]=UserVoteInfo(_username,_candidateId);
      electionUsers[_electionName].cnt++;
    }
      if(userVotes[_username].length>0)
        userVotes[_username].push(_candidateId);
      else
        userVotes[_username]=[_candidateId];
    }
  function getVote(string memory _id) public view returns(uint)  {
    return candidatesVote[_id].vote;
  }
  function getVoteForCandidate(string memory _username,uint  index) public view returns(string memory)  {
    return userVotes[_username][index];
  }
  function getVoteForCandidateLength(string memory _username) public view returns(uint)  {
    return userVotes[_username].length;
  }
  
}