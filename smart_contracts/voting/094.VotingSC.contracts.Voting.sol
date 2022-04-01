pragma solidity ^0.4.24; 

import "./ERC20.sol";

/// @author autumn84 - <yangli@loopring.org>
contract Voting {
  /* 
  The key of the mapping is candidate name stored as type bytes32 and value is
  an unsigned integer which used to store the vote count
  */
  mapping (bytes32 => uint256) public votesReceived;

  mapping (address => bool) public voteFlag;
  
  /* Solidity doesn't let you create an array of strings yet. We will use an array of bytes32 instead to store
  the list of candidates
  */
  
  address lrcAddress = 0x0;

  bytes32[] public candidateList;

  constructor(address _lrcAddress, bytes32[] candidateNames) public {
    require(_lrcAddress != 0x0);
    lrcAddress = _lrcAddress;

    candidateList = candidateNames;
  }

  function totalVotesFor(bytes32 candidate) public view returns (uint256) {
    require(validCandidate(candidate));

    return votesReceived[candidate];
  }

  function voteForCandidate(bytes32 candidate) public {
    require(validCandidate(candidate));
    require(voteFlag[msg.sender] != true);

    uint256 balance = ERC20(lrcAddress).balanceOf(msg.sender);
    votesReceived[candidate] += balance;
    voteFlag[msg.sender] == true;
  }

  function validCandidate(bytes32 candidate) public view returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    
    return false;
  }

  // This function returns the list of candidates.
  function getCandidateList() public view returns (bytes32[]) {
    return candidateList;
  }
}
