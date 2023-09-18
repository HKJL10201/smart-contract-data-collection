pragma solidity ^0.4.24;

contract Election{
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }
    mapping(uint => Candidate) public candidates;
    //store accounts that have voted
    mapping(address => bool) public voters;
    uint public noOfCandidates;

    function Election() public{
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate(string _name) private {
        noOfCandidates++;
        candidates[noOfCandidates] = Candidate(noOfCandidates,_name,0);
    }
    function vote(uint _candidateId) public{
        // track the voting account
        require(!voters[msg.sender],"You have already voted");
        require(_candidateId > 0 && _candidateId<noOfCandidates,"Not a valid candiadate");
        voters[msg.sender] = true;
        // update candidate vote count
        candidates[_candidateId].voteCount ++;
    }
}