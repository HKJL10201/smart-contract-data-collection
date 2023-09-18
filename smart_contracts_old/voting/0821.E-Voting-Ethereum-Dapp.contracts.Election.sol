pragma solidity ^0.4.24;

contract Election {
    //Constructor
    //Read & Store candidate
    //string public candidate; //state vaiable (without _ ): accessable inside a contract 
    
    //Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    
    //Store  Candidates
    //Fetch  Candidate
    mapping (uint => Candidate) public candidates;
    
    //Store  Candidates Count
    uint public candidatesCount;


    //Store  Accounts That have voted
    mapping (address => bool) public voters;

    //voted event
    event votedEvent (
        uint indexed _candidateId
    );


    function Election () public {
        //candidate = "candidate1"; 
        addCandidate("Muddassir");
        addCandidate("Junaid");
    }

    function addCandidate (string _name) private { //_name is local variable therefore _ is there
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateId) public {
        //require that they haven't voted before
        require(!voters[msg.sender]); //if require is ture the reset function is excuted else function breaks here

        //require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        //record that voter has voted
        //msg.sender //this gives us info about the user who has called the vote function
        voters[msg.sender] = true;

        //update candidate vote count 
        candidates[_candidateId].voteCount ++;
    
        //tigger voted event
        votedEvent(_candidateId);
    }

}