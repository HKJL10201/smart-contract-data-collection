pragma solidity ^0.5.0;

contract Election {
    // model a candidate
    // this is basically describe about how our candidate looks like (has a name, a id and vote count)
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // storing the accounts that have already voted
    mapping(address=>bool) public voters;
    // store a candidate
    mapping(uint=>Candidate) public candidates; // creating the variable of that mapping
    // fetch candidate 
    
    
    // get candidate count
    uint public candidatesCount;     // this is the counter

    // voting event 
    event votedEvent (
        uint indexed _candidateId
    );
    
    constructor() public{
       // we dont want any one else to add the candidates therefore we call the addCandidate function in the constructor
        addCandidates("Candidate 1");
        addCandidates("Candidate 2");
        addCandidates("Candidate 3");
        // candidates count is 3
    }
    // adding the candidate to the mapping
    function addCandidates(string memory _name) private {
        candidatesCount++; // this will increment the candidate counter
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0); // assiging value to the candidate structure
    }
    function vote(uint _candidateId) public{
        //check that the address has not voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        // record that voter has voted
        voters[msg.sender] = true; // msg.sender has the account of the voter

        // update candidate vote count
        candidates[_candidateId].voteCount++;

        emit votedEvent(_candidateId);
    }
}