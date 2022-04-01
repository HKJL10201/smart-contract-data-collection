pragma solidity ^0.4.21;

contract Voting {
    
    struct Candidate {
        string candidateName;
        uint voteCount;
    }
    
    struct Voter {
        bool isAuthorized;
        bool hasVoted;
        uint voteFor;   
    }
    
    modifier checkForOwner() {
         require(msg.sender == owner);
         _;
    }
    
    address public owner;
    
    mapping(address => Voter) public voters;
    Candidate[] public candidates;
    uint public totalVotes;
    
    function Voting() public {
        owner = msg.sender;
    }
    
    function addCandidate(string _name) checkForOwner public {
        candidates.push(Candidate(_name,0));
    }
    
    function getTotalCandidates() public view returns(uint) {
        return candidates.length;       
    }
    
    function authorize(address _person) checkForOwner public {
        voters[_person].isAuthorized = true;
    }
    
    function vote(uint _candidateNumber) public {
        require(!voters[msg.sender].hasVoted);
        require(voters[msg.sender].isAuthorized);    
        
        voters[msg.sender].voteFor = _candidateNumber;
        voters[msg.sender].hasVoted = true;

        candidates[_candidateNumber].voteCount += 1;
        totalVotes += 1;
        
    }
    
    function end() checkForOwner public {
        selfdestruct(owner);
    }
     
}