pragma solidity ^0.4.2;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Read/write candidates
    mapping(uint => Candidate) public candidates;

    // storing the accounts in a master list
    mapping(address => bool) public voters;
    
    // Store Candidates Count
    uint public candidatesCount;

    // this is the old way of doing things, now you can use a 'constructor for functions with the same name as the contract'
    //function Election () public {
    
    constructor() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate (string _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }


    function vote (uint _candidateId) public {

        // making sure the voter hasn't voted yet.
        require (
            !voters[msg.sender],
            // below is the error message if this fails
            "Voter has already voted!!!"
            );

        require (
        
            // require a valid cadidateId
            _candidateId > 0 && _candidateId <= candidatesCount,
            "Invalid Candidate!!!"
        );

        // record that the voter has voted
        voters[msg.sender] = true;

        // Update the candidates vote count
        candidates[_candidateId].voteCount ++;
    }

}