pragma solidity ^0.5.12;
//we declare the smart contract with the "contract" keyword 
contract Election { 
    // Model a Candidate 
    struct Candidate { 
        uint id; 
        string name; 
        uint voteCount;
    }
    // Store accounts that have voted 
    mapping(address => bool) public voters;
    // Read/write candidates 
    mapping(uint => Candidate) public candidates;
    // Store Candidates Count 
    uint public candidatesCount;
    event votedEvent ( uint indexed _candidateId
    );
    //create a constructor that will get called whenever we deploy the smart contract to the blockchain.
    constructor () public {

        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
        addCandidate("Candidate 3");
    }

    function addCandidate (string memory _name) private { candidatesCount ++; 
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }
    function vote (uint _candidateId) public { 
        // require that they haven’t voted before 
        require(!voters[msg.sender]); 
        // require a valid candidate 
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        // record that voter has voted 
        voters[msg.sender] = true;
        // update candidate vote Count 
        candidates[_candidateId].voteCount ++;
        emit votedEvent(_candidateId); 
    }
}