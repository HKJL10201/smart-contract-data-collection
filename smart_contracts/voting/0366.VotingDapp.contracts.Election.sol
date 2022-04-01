pragma solidity ^0.4.24;

contract Election {
    // Candidate strct/model
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    //recording voted or not
    mapping(address => bool) public voters;
    //fetch the data
    mapping(uint => Candidate) public candidates;   
    // candidates count
    uint public candidatesCount;

    //events
    event votedEvent (
        uint indexed _candidateId
    );
    //Constructor
    function Election() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    //Add Candidates
    function addCandidate(string _name) private {
        candidatesCount++;
        candidates[candidatesCount]= Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        votedEvent(_candidateId);
    }

}