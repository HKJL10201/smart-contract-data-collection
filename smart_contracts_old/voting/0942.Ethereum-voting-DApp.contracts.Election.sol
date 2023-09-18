pragma solidity ^0.4.2;

contract Election {
   //Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    //Store account that have voted
    mapping(address=>bool) public voters;
   //Store canidates
   //Fetch candidate
    mapping(uint=>Candidate) public candidates;
      //Store candidate Count
    uint public candidateCount;
    function Election() public{
        addCandidate("Ram Singh");
        addCandidate("Hari Bhai");
    }
    function addCandidate(string _name) private {
        candidateCount++;
        candidates[candidateCount]=Candidate(candidateCount,_name,0);
    }

    function vote(uint _candidateId) public{
        //required that they have't voteed before
        require(!voters[msg.sender]);

        //required a valid candidate
        require(_candidateId >0 && _candidateId<=candidateCount);
        
        //record voter has voted
        voters[msg.sender]=true;
        //update vote count
        candidates[_candidateId].voteCount++;
    }
}