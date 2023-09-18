pragma solidity >=0.4.22;

contract Election {

    //Struct for candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    //Store the voters
    mapping(address => bool) public voters;

    //Fetch candidate by id
    mapping(uint => Candidate) public candidates;

    uint public candidatesCount;

    //Constructor
    constructor() public { 
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    //function to add candidate
    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    //function to vote
    function vote(uint _candidateId) public {
        require(!voters[msg.sender]);
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        candidates[_candidateId].voteCount++;
        voters[msg.sender] = true;
    }
}