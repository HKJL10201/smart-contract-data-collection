//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract Voting {
    
    uint256 counter = 0;
    uint256 public startTime;
    uint256 public endTime;
    
    struct Candidate {
        uint256 id;
        string name;
        uint256 totalVotes;
        address[] alreadyVotedAddress;
    }
    
    mapping(uint256 => Candidate) public candidates;
    
    Candidate[] public candidateCollec;
    
    function startVoting() public {
        startTime = block.timestamp;
        endTime = startTime + (10 * 1 minutes);
    }
    
    function addCandidate(string memory _name) public {
        require(candidateCollec.length < 3, "Max 3 Candidates can be there in the election");
        
        counter = counter + 1;
        uint256 _uniqueId = counter;
        candidates[_uniqueId].id = _uniqueId;
        candidates[_uniqueId].name = _name;
        
        candidateCollec.push(candidates[_uniqueId]);
    }
    
    function vote(uint256 _candidateId) public {
        // Check if voting is happening within 10 minutes or after 10 minutes.
        require(block.timestamp <= endTime, "Voting Time expired. Voting was only for 10 minutes.");
        
        require(candidates[_candidateId].id != 0, "No candidate present with this id");
        
        bool _isAlreadyVoted = false;
        Candidate memory _candidate = candidates[_candidateId];
        for(uint i = 0; i < _candidate.alreadyVotedAddress.length; i++) {
            if(_candidate.alreadyVotedAddress[i] == msg.sender) {
                _isAlreadyVoted = true;
            }
        }
        require((_isAlreadyVoted == false && _candidate.alreadyVotedAddress.length <= 10), "Max 10 voters can vote to this candidate and same voter can't vote more than once."); 
        candidates[_candidateId].totalVotes += 1;
        candidates[_candidateId].alreadyVotedAddress.push(msg.sender);
    }
    
    function getResult() public view returns(uint256) {
        // Check if result is declaring after 10 minutes or not.
        require(block.timestamp > endTime, "Result will be declared after 10 minutes of Voting.");
        
        uint256 _maxVotes = 0;
        uint256 _winnerId = 0;
        for(uint i = 0; i < candidateCollec.length; i++) {
            _winnerId = (candidateCollec[i].totalVotes > _maxVotes) ? candidateCollec[i].id : _winnerId;
            _maxVotes = (candidateCollec[i].totalVotes > _maxVotes) ? candidateCollec[i].totalVotes : _maxVotes;
        }
        
        return _winnerId;
    }
}
