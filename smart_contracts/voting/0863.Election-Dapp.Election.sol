pragma solidity ^0.4.18;

contract Election {
    //model a candidate
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }
    // Store accounts that have voted
    // Store Candidates
    // Fetch Candidates
    mapping(address=>bool) public voters;
    mapping(uint=>Candidate) public candidates;
    uint public candidatesCount;
    function Election() public{
        addCandidate("Candidate1");
        addCandidate("Candidate2");
    }
    function addCandidate(string _name) private{
        candidatesCount++;
        candidates[candidatesCount]=Candidate(candidatesCount,_name,0);
    }
    function vote(uint _candidateId) public{
        // require that they haven't voted before
        require(voters[msg.sender]==false);
        // require a valid candidate
        require(_candidateId>0 && _candidateId<=candidatesCount);
        // record that voter has voted
        voters[msg.sender]=true;
        //update vote voteCount
        candidates[_candidateId].voteCount++;

    }
}
