// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Election {

    // Creatimg a candidates structure

    address public owner;

    struct Candidate {
        uint id;
        string name;
        uint Count_Of_Votes;
    }

    modifier onlyOwner{
        require(owner == msg.sender, "Only owner can call this");
        _;
    }

    // We load and fetch the number of our voters through the use of mapping
    mapping(address => bool) public voters;

    mapping(uint => Candidate) public candidates;

    // Storing Candidates Count
    uint public CountOfCandidates;

    // voted event
    event votedEvent (
        uint indexed _candidateId
    );

    constructor() public payable{
        owner = msg.sender;
    }

    function NewCandidate (string memory _name) public onlyOwner{
        CountOfCandidates ++;
        candidates[CountOfCandidates] = Candidate(CountOfCandidates, _name, 0);
    }

    function vote(uint _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender], "you have allready voted");

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= CountOfCandidates);

        // check if a voter has already voted
        voters[msg.sender] = true;

        // Update the total number of votes
        candidates[_candidateId].Count_Of_Votes++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }
}
