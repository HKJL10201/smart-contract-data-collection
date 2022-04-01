pragma solidity ^0.5.16;

contract Voting {
  
  struct values{
      bool exists;
      uint index;
  }
         
  mapping(uint => bool) public voted;
  mapping (string => uint) public votesReceived;
  mapping (string => values) public candidateIndex;
  uint public total=5;
  string[] public  candidateList=new string[](total);
  string public adminpwd;  
  bool public declared;
  uint public candidateCount;
  
  function addCandidate(string memory candidate) public returns (uint){
      if(!declared && candidateCount<=5){
    candidateList[candidateCount]=candidate;
    candidateCount++;
    candidateIndex[candidate].exists=true;
    candidateIndex[candidate].index=candidateCount-1;
    return 1;
      } 
      return 0;
  }


  function totalVotesFor(string memory candidate) view public returns (uint) {
      return votesReceived[candidate];
  }
    
  function getTotal() view public returns (uint) {
      return total;
  }
  
  function getcandidateCount() view public returns (uint) {
      return candidateCount;
  }
    

  function voteForCandidate(string memory candidate,uint aadharnum) public returns (uint){
   //require(validCandidate(candidate));
    votesReceived[candidate] += 1;
    voted[aadharnum]=true;
    return 1;
   
  }
  
  
  function isExists(string memory candidate) view public returns (bool) {
    return candidateIndex[candidate].exists;
  }
  
  function Declare() public returns (bool) {
    declared=true;
    return declared;
  }
  
  function isDeclared() public view returns (bool){
      return declared;
  }
  
  function getPwd() public view returns (string memory){
      return adminpwd;
  }
  
  function changePwd(string memory new_pwd) public returns (string memory){
      adminpwd=new_pwd;
      return adminpwd;
  }
 
   function allCandidates(uint y) public view returns (string memory,string memory,string memory,string memory,string memory){
      return (candidateList[0],candidateList[1],candidateList[2],candidateList[3],candidateList[4]);
  }
 
   function removeCandidate(string memory candidate) public  returns (bool){
       if(candidateIndex[candidate].exists){
        for(uint i=candidateIndex[candidate].index ; i<total-1 ;i++)
        {
           candidateList[i]=candidateList[i+1];
           candidateIndex[candidateList[i]].index=i+1;
        }
        candidateCount--;
        candidateIndex[candidate].exists=false;
        candidateIndex[candidate].index=0;
       delete candidateList[4];
       return true;
       }
       return false;
  }
  
  function hasVoted(uint aadhar) view public returns (bool) {
    return voted[aadhar];
  }
  
  function getWinner(uint uy) view public returns (string memory){
      uint curr=uy;
      uint idx;
      uint xor=0;
      for (uint i=0;i<candidateList.length;i++){
          if(votesReceived[candidateList[i]]>curr){
          curr=votesReceived[candidateList[i]];
          idx= i;
            }
            xor=xor^votesReceived[candidateList[i]];
  } 
  if(xor==0)
  { return "Draw"; }
    return candidateList[idx];
}

    
            }