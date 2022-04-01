pragma solidity ^0.4.24;

contract owned {

  address public owner;

  constructor()  public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner  public {
    owner = newOwner;
  }

}

contract tokenRecipient {

  event receivedEther(address sender, uint amount);
  event receivedTokens(address _from, uint256 _value, address _token, bytes _extraData);

  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
    Token t = Token(_token);
    require(t.transferFrom(_from, this, _value));
    emit receivedTokens(_from, _value, _token, _extraData);
  }

  function () payable  public {
    emit receivedEther(msg.sender, msg.value);
  }

}

interface Token {
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract voting is owned, tokenRecipient {

  struct List {
    uint256 voteCount;
  }

  struct Candidate {
    uint256 voteCount;
    List[] lists;
  }

  Candidate[] candidates;

  constructor(uint256 _numCandidates) public {
    candidates.length = _numCandidates;
    if (_numCandidates > 0){
      candidates[0].lists.length = 1;
    }
  }

  function setNumCandidates(uint256 _numCandidates) onlyOwner public {
    candidates.length = _numCandidates;
    if (_numCandidates > 0){
      candidates[0].lists.length = 1;
    }
  }

  function getNumCandidates() public constant returns(uint){
    return candidates.length;
  }

  function getNumCandidateLists(uint256 candidateID) public constant returns(uint){
    if (candidateID < candidates.length){
      return candidates[candidateID].lists.length;
    }else{
      return 0;
    }
  }

  function voteCandidate(uint256 candidateID) public{
    if (candidateID <= candidates.length){
      candidates[candidateID].voteCount++;
      for (uint8 i = 0; i<candidates[candidateID].lists.length; i++){
        candidates[candidateID].lists[i].voteCount++;
      }
    }
  }

  function voteList(uint256 candidateID, uint256 listID) public{
    if (candidateID <= candidates.length){
      candidates[candidateID].voteCount++;
      if (listID >= candidates[candidateID].lists.length){
        candidates[candidateID].lists.length = listID + 1;
      }
      candidates[candidateID].lists[listID].voteCount++;
    }
  }

  function getCandidateVote(uint256 candidateID) public constant returns(uint256){
    if (candidateID < candidates.length){
      return candidates[candidateID].voteCount;
    }else{
      return 0;

    }
  }

  function getListVote(uint256 candidateID, uint256 listID) public constant returns(uint256){
    if (candidateID < candidates.length){
      if (listID < candidates[candidateID].lists.length){
        return candidates[candidateID].lists[listID].voteCount;
      }else{
        return 0;
      }
    }else{
      return 0;
    }
  }

  function getNumWinnerCandidates() public constant returns(uint256){
    uint256 max = candidates[0].voteCount;
    uint256 num = 1;
    for (uint256 i = 1; i < candidates.length; i++){
      if (candidates[i].voteCount > max){
        max = candidates[i].voteCount;
      }else if(candidates[i].voteCount == max){
        num++;
      }
    }
    return num;
  }

  function getWinnerCandidate() public constant returns(uint256){
    uint256 max = candidates[0].voteCount;
    uint256 index = 0;
    for (uint256 i = 1; i < candidates.length; i++){
      if (candidates[i].voteCount > max){
        max = candidates[i].voteCount;
        index = i;
      }
    }
    return index;
  }

  function getNumWinnerList() public constant returns(uint256){
    uint256 max = candidates[0].voteCount;
    uint256 index = 0;
    for (uint256 i = 1; i < candidates.length; i++){
      if (candidates[i].voteCount > max){
        max = candidates[i].voteCount;
        index = i;
      }
    }
    uint256 num = 1;
    for (uint256 j = 0; i < candidates[index].lists.length; i++){
      max = candidates[index].lists[j].voteCount;
      if (candidates[index].lists[j].voteCount > max){
        max = candidates[index].lists[j].voteCount;
      }else if(candidates[index].lists[j].voteCount == max){
        num++;
      }
    }
    return num;
  }

  function getWinnerListFromCandidate(uint256 candidateID) public constant returns(uint){
    if (candidateID < candidates.length){
      uint256 max = candidates[candidateID].lists[0].voteCount;
      uint256 index = 0;
      for (uint256 i = 1; i < candidates[candidateID].lists.length; i++){
        if (candidates[candidateID].lists[i].voteCount > max){
          max = candidates[candidateID].lists[i].voteCount;
          index = i;
        }
      }
      return index;
    }else{
      return 0;
    }

  }

  function getWinnerList() public constant returns(uint){
    uint256 candidateID = getWinnerCandidate();
    return getWinnerListFromCandidate(candidateID);
  }

  function reset() onlyOwner public {
    candidates.length = 0;
  }

  function kill() onlyOwner public {
    selfdestruct(msg.sender);
  }

}
