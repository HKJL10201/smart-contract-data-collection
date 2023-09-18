pragma solidity ^0.8.0;

contract Voting {
    
    mapping (address => bool) public hasVoted;
    mapping (string => uint256) public votes;
    string[] public candidates;
    
    constructor(string[] memory _candidates) {
        candidates = _candidates;
    }
    
    function vote(string memory _candidate) public {
        require(!hasVoted[msg.sender], "You have already voted");
        require(validCandidate(_candidate), "Not a valid candidate");
        votes[_candidate]++;
        hasVoted[msg.sender] = true;
    }
    
    function validCandidate(string memory _candidate) view public returns (bool) {
        for (uint i = 0; i < candidates.length; i++) {
            if (keccak256(bytes(candidates[i])) == keccak256(bytes(_candidate))) {
                return true;
            }
        }
        return false;
    }
    
    function getVotes(string memory _candidate) view public returns (uint256) {
        return votes[_candidate];
    }
}
