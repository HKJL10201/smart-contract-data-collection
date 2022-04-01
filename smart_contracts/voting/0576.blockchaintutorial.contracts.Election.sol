pragma solidity ^0.4.2;

contract Election {
    struct Candidate {  
        uint id;
        string name;
        uint voteCount;
    }

    //Store accounts that have voted
    mapping(address => bool) public voters;

    //Store Candidate
    //Fetch Candidate 
    //writing to blockchain using the mapping
    mapping(uint => Candidate) public candidates;
    //Store Candidates Count
    uint public candidatesCount;

    //string public candidate;
    //Constructor - run each time we initialise our contract upon migration
    function Election() public {
        //candidate ="Candidate 1";
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }
    function addCandidate(string _name) private {
        candidatesCount++;
        candidates[candidatesCount]=Candidate(candidatesCount, _name, 0);
    }
    function vote(uint _candidateId) public {
        //require that they haven't voted bfore
        require(!voters[msg.sender]);
        //require a valid candidate
        require(_candidateId > 0 && _candidateId <=candidatesCount);
        //record that voter has voted. 
        voters[msg.sender] = true;
        //update candidate vote count
        candidates[_candidateId].voteCount++;
    }

}