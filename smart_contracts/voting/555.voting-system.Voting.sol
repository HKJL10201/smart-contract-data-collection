//SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Voting {
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    mapping(string => bytes32) candidateId;
    mapping(string => uint) candidateVotes;
    string[] candidates;
    mapping(bytes32 => bool) public voters;
    
    function nominateMeAsCandidate(
        string memory _name,
        uint _age,
        string memory _id
    ) public {
        bytes32 candidateHash = keccak256(abi.encodePacked(_name, _age, _id));
        candidateId[_name] = candidateHash;
        candidates.push(_name);
    }
    
    function getCandidates() public view returns(string[] memory) {
        return candidates;
    }
    
    function hasVoted(bytes32 _voterHash) private view returns(bool) {
        return voters[_voterHash];
    }
    
    function vote(string memory _candidateName) public {
        bytes32 voterHash = keccak256(abi.encodePacked(msg.sender));
        bool _hasVoted = hasVoted(voterHash);
        require(_hasVoted!=true, "You have already voted.");
        voters[voterHash] = true;
        candidateVotes[_candidateName]++;
    }
    
    function getCandidateVotes(string memory _candidateName) public view returns(uint) {
        return candidateVotes[_candidateName];
    }
    
    function uint2str(uint256 _i) internal pure returns (string memory str) {
      if (_i == 0) {
        return "0";
      }
      uint256 j = _i;
      uint256 length;
      while (j != 0) {
        length++;
        j /= 10;
      }

      bytes memory bstr = new bytes(length);
      uint256 k = length;
      j = _i;
      while (j != 0) {
        bstr[--k] = bytes1(uint8(48 + j % 10));
        j /= 10;
      }
      str = string(bstr);
    }
    
    function getVotes() public view returns(string memory) {
        string memory results = "";
        for(uint i = 0; i < candidates.length; i++) {
            results = string(abi.encodePacked(results, "{", candidates[i], ": ", uint2str(getCandidateVotes(candidates[i])), "}, "));
        }
        
        return results;
    }
    
    function winner() public view returns(string memory) {
        string memory winningCandidate = candidates[0];
        bool flag;
        for(uint i=0; i < candidates.length; i++) {
            if(candidateVotes[candidates[i]] > candidateVotes[winningCandidate]) {
                winningCandidate = candidates[i];
                flag = false;
            } else {
                if(candidateVotes[candidates[i]] == candidateVotes[winningCandidate]) {
                    flag = true;
                }
            }
        }
        if(flag == true) {
            winningCandidate = "The vote ended in a tie!";
        }
        
        return winningCandidate;
    }
    
    
}
